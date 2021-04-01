# Get AzureRM Terraforn Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # version = "2.31.1" Or Greater Required for WVD
      version = "=2.46.0"
    }
  }
}
provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "rgwvd01" {
  name     = var.rgname
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
  maximum_sessions_allowed = 10

  registration_info {
    expiration_date = "2021-04-03T08:00:00Z" # Must be set to a time between 1 hour in the future & 27 days in the future
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
# Existing Network Data
#----------------------------------

# refer to a resource group
data "azurerm_resource_group" "test" {
  name = "nancyResourceGroup"
}

#refer to a subnet
data "azurerm_subnet" "test" {
  name                 = "mySubnet"
  virtual_network_name = "myVnet"
  resource_group_name  = "nancyResourceGroup"
}

#----------------------------------
# Session Host VM
#----------------------------------

# Create a NIC for the Session Host VM
resource "azurerm_network_interface" "wvd_vm1_nic" {
  name                = "NicNameGoesHere"
  resource_group_name = azurerm_resource_group.rgwvd01.name
  location            = azurerm_resource_group.rgwvd01.location

  ip_configuration {
    name                          = "IpConfigNameGoesHere"
    subnet_id                     = "Azure Subnet ID to attach the NIC to"
    private_ip_address_allocation = "dynamic"
  }
}

# Create the Session Host VM
resource "azurerm_windows_virtual_machine" "wvd_vm1" {
  name                  = "VMNameGoesHere"
  resource_group_name   = azurerm_resource_group.rgwvd01.name
  location              = azurerm_resource_group.rgwvd01.location
  size                  = "Standard_B1s"
  network_interface_ids = [ azurerm_network_interface.wvd_vm1_nic.id ]
  provision_vm_agent    = true
  timezone              = "Central Standard Time"
  
  admin_username = "localadmin"
  admin_password = "LocalPass2021"
    
  os_disk {
    name                 = "DiskNameGoesHere"
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

# VM Extension for Domain-join
resource "azurerm_virtual_machine_extension" "vm1ext_domain_join" {
  name                       = "ExtensionName1GoesHere"
  virtual_machine_id         = azurerm_windows_virtual_machine.wvd_vm1.id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "Name": "domain.com",
      "OUPath": "OU=secondlevel,OU=firstlevel,DC=domain,DC=com",
      "User": "AdminUsername@domain.com",
      "Restart": "true",
      "Options": "3"
    }
    SETTINGS

  protected_settings = <<-PSETTINGS
    {
      "Password":"AdminPasswordGoesHere"
    }
    PSETTINGS

  lifecycle {
    ignore_changes = [ settings, protected_settings ]
  }
}

# VM Extension for Desired State Config
resource "azurerm_virtual_machine_extension" "vm1ext_dsc" {
  name                       = "ExtensionName2GoesHere"
  virtual_machine_id         = azurerm_windows_virtual_machine.wvd_vm1.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  
  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "hostPoolName": "HostPool1NameGoesHere",
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool.wvd_pool1.registration_info[0].token}"
      }
    }
    SETTINGS

  lifecycle {
    ignore_changes = [ settings ]
  }

  depends_on = [ azurerm_virtual_machine_extension.ext_domain_join ]
}
