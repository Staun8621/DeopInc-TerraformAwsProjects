# create an availability set
resource "azurerm_availability_set" "frontend" {
  name                         = "tf-avail-set"
  location                     = var.arm_region
  resource_group_name          = var.arm_resource_group_name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 20
  managed                      = true
  tags = {
    environment = "Production"
  }
}

# create a container for the storage account
resource "azurerm_storage_container" "frontend" {
  count                 = var.arm_frontend_instances
  name                  = "tf-storage-container-${count.index}"
  storage_account_name  = azurerm_storage_account.frontend.name
  container_access_type = "private"
}

# create a network interface frontend
resource "azurerm_network_interface" "frontend" {
  count               = var.arm_frontend_instances
  name                = "tf-interface-${count.index}"
  location            = var.arm_region
  resource_group_name = var.arm_resource_group_name

# ip_configuration {
  ip_configuration {
    name                          = "tf-ip-${count.index}"
    subnet_id                     = azurerm_subnet.my_subnet_frontend.id
    private_ip_address_allocation = "Dynamic"
  }
}

# create a virtual machine frontend
resource "azurerm_virtual_machine" "frontend" {
  count                 = var.arm_frontend_instances
  name                  = "tf-instance-${count.index}"
  location              = var.arm_region
  resource_group_name   = var.arm_resource_group_name
  network_interface_ids = ["${element(azurerm_network_interface.frontend.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = azurerm_availability_set.frontend.id

# virtual machine image
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

# vurtual machine OS disk
  storage_os_disk {
    name              = "tf-osdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # Optional data disks
  storage_data_disk {
    name              = "tf-datadisk-${count.index}"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "1023"
    create_option     = "Empty"
    lun               = 0
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

# virtual machine OS profile
  os_profile {
    computer_name  = "tf-instance-${count.index}"
    admin_username = "demo"
    admin_password = var.arm_vm_admin_password
  }

# virtual machine OS profile Linux config
  os_profile_linux_config {
    disable_password_authentication = false
  }

}
