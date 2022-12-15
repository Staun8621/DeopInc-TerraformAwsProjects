# assign variable for location of resources
variable "arm_region" {
  description = "The Azure region to create things in."
  default     = "East US"
}

# assign variable for vm admin password
variable "arm_vm_admin_password" {
  description = "Passwords for the root user in VMs."
  default     = "easyy.321-" # This should be hidden and passed as variable, doing this just for training purpose
}

# assign variable for number of frontend instances
variable "arm_frontend_instances" {
  description = "Number of front instances"
  default     = 2
}

# assign variable for resource group name
variable "arm_resource_group_name" {
  description = "The name of the resource group to create."
  default     = "MehmetOsanmazRG"
}
