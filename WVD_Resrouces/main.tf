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

#----------------------------------
# Resource Group
#----------------------------------
resource "azurerm_resource_group" "rgwvd01" {
  name     = var.wvd_rg_name
  location = var.region
}

#----------------------------------
# WVD Resources
#----------------------------------

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