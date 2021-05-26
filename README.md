# AzWVD-TFDeploy
This repository contains example Terraform templates for deploying [Windows Virtual Desktop (WVD)](https://docs.microsoft.com/en-us/azure/virtual-desktop/overview) on Azure. The templates in the root of the repository will deploy the nessecary WVD resources and Windwos 10 Multisession Host VMs.

To deploy WVD resrouces only (Host Pool / App Groups / Workspace) only and **NO** WVD Host VMs use the templates located in the [WVD_Resources Folder](https://github.com/cocallaw/AzWVD-TFDeploy/tree/main/WVD_Resrouces) 

To deploy WVD resources the template files utilize the following Desktop Virtualization resources from the [AzureRM](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) Terraform Provider
- [virtual_desktop_application_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application_group)
- [virtual_desktop_host_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool)
- [azurerm_virtual_desktop_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace)
- [azurerm_virtual_desktop_workspace_application_group_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace_application_group_association) 
