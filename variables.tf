variable "arm_region" {
  description = "The Azure region to create things in."
  default     = "East US"
}
variable "arm_vm_admin_password" {
  description = "Passwords for the root user in VMs."
  default     = "easyy.321-" # This should be hidden and passed as variable, doing this just for training purpose
}

variable "arm_frontend_instances" {
  description = "Number of front instances"
  default     = 2
}
