# Get AzureRM Terraforn Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # version = "2.31.1" Or Greater Required for WVD
      version = "=2.64.0"
    }
  }
}
provider "azurerm" {
  features {}
}

# Create Resource Group for all resources
resource "azurerm_resource_group" "rgwvd01" {
  name     = var.wvd_rg_name
  location = var.region
}

# Create WVD Host Pool that is a Pooled Type
resource "azurerm_virtual_desktop_host_pool" "wvdpool01" {
  location            = var.region
  resource_group_name = azurerm_resource_group.rgwvd01.name
  name                     = var.pooledhpname
  friendly_name            = var.pooledhpfriendlyname
  description              = var.pooledhpdescription
  type                     = "Pooled"
  load_balancer_type       = "BreadthFirst" # Options: BreadthFirst / DepthFirst
  maximum_sessions_allowed = var.pooledhpsessionlimit

  registration_info {
    expiration_date = timeadd(timestamp(), "2h30m")  # Must be set to a time between 1 hour in the future & 27 days in the future
  }
}

#Create Desktop Application Group (DAG) for wvdpool01
resource "azurerm_virtual_desktop_application_group" "wvdpool01DAG" {
  name                = var.pooledhpdesktopappname
  location            = var.region
  resource_group_name = azurerm_resource_group.rgwvd01.name

  type          = "Desktop"
  host_pool_id  = azurerm_virtual_desktop_host_pool.wvdpool01.id
  friendly_name = var.pooledhpdesktopappfriendlyname
  description   = var.pooledhpdesktopappdescription
}

#Create RemoteApp Application Group
resource "azurerm_virtual_desktop_application_group" "wvdpool01AppG" {
  name                = var.pooledhpremoteappname
  location            = var.region
  resource_group_name = azurerm_resource_group.rgwvd01.name

  type          = "RemoteApp"
  host_pool_id  = azurerm_virtual_desktop_host_pool.wvdpool01.id
  friendly_name = var.pooledhpremoteappfriendlyname
  description   = var.pooledhpremoteappdescription
}

# Create Workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace
  location            = var.region
  resource_group_name = azurerm_resource_group.rgwvd01.name

  friendly_name = var.workspacefriendlyname
  description   = var.workspacedesc
}

# Associate RemoteApp Application Group with Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "workspaceremoteapp" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.wvdpool01AppG.id

}

# Associate Desktop Application Group with Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "workspacedesktop" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.wvdpool01DAG.id
}

#----------------------------------
# Existing Virtual Network Data
#----------------------------------

#refrence to existing subnet
data "azurerm_subnet" "wvd_host_subnet" {
  name                 = var.vnet_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_rg_name
}

#----------------------------------
#  Create Session Host VM
#----------------------------------

# Create a NIC for the Session Host VM
resource "azurerm_network_interface" "wvd_vm_nic" {
  count               = var.wvdhostcount
  name                = "${var.wvdvmbasename}-nic-${count.index}"
  resource_group_name = azurerm_resource_group.rgwvd01.name
  location            = azurerm_resource_group.rgwvd01.location

  ip_configuration {
    name                          = "IpConfig01"
    subnet_id                     = data.azurerm_subnet.wvd_host_subnet.id
    private_ip_address_allocation = "dynamic"
  }
}

# Create the Session Host VM
resource "azurerm_windows_virtual_machine" "wvd_vm" {
  count                 = var.wvdhostcount
  name                  = "${var.wvdvmbasename}-${count.index}"
  resource_group_name   = azurerm_resource_group.rgwvd01.name
  location              = azurerm_resource_group.rgwvd01.location
  size                  = "Standard_DS3_v2"
  network_interface_ids = [ azurerm_network_interface.wvd_vm_nic.*.id[count.index] ]
  provision_vm_agent    = true
  
  admin_username = "wvdlocaladmin"
  admin_password = "SuperSecretWVD123"
    
  os_disk {
    name                 = "OSDisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  boot_diagnostics {
    storage_account_uri = ""  # A null value will utilize Managed Storage Account to store Boot Diagnostics
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-evd"                                 # This is the Windows 10 Enterprise Multi-Session image
    version   = "latest"
  }
}

#----------------------------------
# Join WVD Host to Active Directory Domain
#----------------------------------
resource "azurerm_virtual_machine_extension" "vmext_domain_join" {
  count                = var.wvdhostcount
  name                 = "join-domain"
  virtual_machine_id   = azurerm_windows_virtual_machine.wvd_vm.*.id[count.index]
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  

  # NOTE: the `OUPath` field is intentionally blank, to put it in the Computers OU
  settings = <<SETTINGS
        {
            "Name": "${var.active_directory_domain}",
            "OUPath": "",
            "User": "${var.active_directory_domain}\\${var.active_directory_username}",
            "Restart": "true",
            "Options": "3"
        }
    SETTINGS

  protected_settings = <<SETTINGS
        {
            "Password": "${var.active_directory_password}"
        }
    SETTINGS

  lifecycle {
    ignore_changes = [ settings, protected_settings ]
  }
}

#----------------------------------
# Perform DSC to configure WVD Host Agents
#----------------------------------
resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count                      = var.wvdhostcount
  name                       = "DSC-Extension"
  virtual_machine_id         = azurerm_windows_virtual_machine.wvd_vm.*.id[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  
  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_3-10-2021.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "hostPoolName": "${var.pooledhpname}",
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool.wvdpool01.registration_info[0].token}"
      }
    }
    SETTINGS

  lifecycle {
    ignore_changes = [ settings ]
  }

  depends_on = [ azurerm_virtual_machine_extension.vmext_domain_join ]
}
