variable "wvd_rg_name" {
  description = "Name of Resource Group to be created for WVD resources"
  default     = "TF-WVD-RG"
}

variable "region" {
  description = "Region for all WVD resoures to be deployed into"
  default     = "East US"
}

variable "wvdhostcount" {
  description = "Number of WVD hosts to deploy"
  default     = 2
}

variable "vnet_rg_name" {
  description = "Name of Resource Group containing existing VNet to be used by WVD Hosts"
  default = "Contoso-Lab-Networking"
}

variable "vnet_name" {
  description = "Name of exiting VNet resouce to be used by WVD Hosts"
  default = "vnet-contoso-lab"
}

variable "vnet_subnet_name" {
  description = "Name of existing Subnet to be used by WVD Hosts"
  default = "subnet"
}

variable "active_directory_domain" {
  description = "WIndows AD Domain to Join WVD Hosts to"
  default     = "contoso.com"
}

variable "active_directory_username" {
  description = "Windows AD uUsernam with permission to join machines to domain"
  default     = "ADUser"
}

variable "active_directory_password" {
  description = "Windows AD Password for account with permission to join machines to domain"
  default     = "ADPassword"
}

variable "pooledhpname" {
  description = "Pooled Host Pool Name"
  default     = "HP01-Pooled"
}

variable "pooledhpsessionlimit" {
  description = "Maximum number of sessions per host in the pool"
  default = 5
}

variable "pooledhpfriendlyname" {
  description = "Pooled Host Pool Friendly Name"
  default     = "HP01 Pooled Host Pool"
}

variable "pooledhpdescription" {
  description = "Pooled Host Pool Description"
  default     = "A Pooled Host Pool"
}

variable "pooledhpdesktopappname" {
  description = "Pooled Host Pool Desktop App Group Friendly Name"
  default     = "HP01-Pooled-DAG"
}

variable "pooledhpdesktopappfriendlyname" {
  description = "Pooled Host Pool Desktop App Group Friendly Name"
  default     = "HP01 Desktop Application Group"
}

variable "pooledhpdesktopappdescription" {
  description = "Pooled Host Pool Desktop App Group Description"
  default     = "A Desktop Application Group for HP01"
}

variable "pooledhpremoteappname" {
  description = "Pooled Host Pool RemoteApp App Group Name"
  default     = "HP01-Pooled-AppGroup"
}

variable "pooledhpremoteappfriendlyname" {
  description = "Pooled Host Pool RemoteApp App Group Friendly Name"
  default     = "HP01 Remote Application Group"
}

variable "pooledhpremoteappdescription" {
  description = "Pooled Host Pool RemoteApp App Group Description"
  default     = "A Remote Application Group for HP01"
}

variable "workspace" {
  description = "WVD Workspace Name"
  default     = "HP01-WS-TF"
}

variable "workspacefriendlyname" {
  description = "WVD Workspace Friendly Name"
  default     = "HP01 Workspace"
}

variable "workspacedesc" {
  description = "WVD Workspace Description"
  default     = "A Workspace for HP01"
}

variable "wvdvmbasename" {
  description = "WVD Base Name Sceme"
  default     = "wvdtf"
}