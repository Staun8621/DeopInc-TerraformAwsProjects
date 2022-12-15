resource "azurerm_storage_account" "frontend" {
    name                     = "tf321123mehmetostracc"
    resource_group_name      = "${var.arm_resource_group_name}"
    location                 = "${var.arm_region}"
    account_tier             = "Standard"
    account_replication_type = "LRS"
}