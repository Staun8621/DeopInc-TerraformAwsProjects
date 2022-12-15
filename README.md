# Name of the Project: Terraform Project in Azure

Description of the Project: This is a Terraform project that can be used to create an Azure virtual machine, virtual network, storage account, and load balancer into your existing resource group. Then, it creates and uploads the tfstate file of your deployment to the existing container in your storage account on Azure without creating it in your local.

## Virtual-machines.tf

The 'virtual-machines.tf' file creates an availability set for the virtual machines, a storage container for each instance, a network interface for each instance, and a virtual machine for each instance. The virtual machine includes storage for an OS disk, storage for an optional data disk, an OS profile, an OS profile Linux configuration, and flags to delete the OS and data disks on termination.

```bash
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

resource "azurerm_storage_container" "frontend" {
  count                 = var.arm_frontend_instances
  name                  = "tf-storage-container-${count.index}"
  storage_account_name  = azurerm_storage_account.frontend.name
  container_access_type = "private"
}

resource "azurerm_network_interface" "frontend" {
  count               = var.arm_frontend_instances
  name                = "tf-interface-${count.index}"
  location            = var.arm_region
  resource_group_name = var.arm_resource_group_name

  ip_configuration {
    name                          = "tf-ip-${count.index}"
    subnet_id                     = azurerm_subnet.my_subnet_frontend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "frontend" {
  count                 = var.arm_frontend_instances
  name                  = "tf-instance-${count.index}"
  location              = var.arm_region
  resource_group_name   = var.arm_resource_group_name
  network_interface_ids = ["${element(azurerm_network_interface.frontend.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"
  availability_set_id   = azurerm_availability_set.frontend.id

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

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

  os_profile {
    computer_name  = "tf-instance-${count.index}"
    admin_username = "demo"
    admin_password = var.arm_vm_admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}
```

## vnet-subnet.tf

The 'vnet-subnet.tf' file creates a resource group, a virtual network, and three subnets, one for the frontend, one for the backend, and one for the DMZ.

```bash
# resource "azurerm_resource_group" "terraform_sample" {
#     name     = "terraform-sample"
#     location = "${var.arm_region}"
# }

resource "azurerm_virtual_network" "my_vn" {
  name                = "tf-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.arm_region}"
  resource_group_name = "${var.arm_resource_group_name}"
}

resource "azurerm_subnet" "my_subnet_frontend" {
  name                 = "frontend"
  resource_group_name  = "${var.arm_resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.my_vn.name}"
  address_prefixes      = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "my_subnet_backend" {
  name                 = "backend"
  resource_group_name  = "${var.arm_resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.my_vn.name}"
  address_prefixes      = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "my_subnet_dmz" {
  name                 = "dmz"
  resource_group_name  = "${var.arm_resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.my_vn.name}"
  address_prefixes      = ["10.0.3.0/24"]
}
```

## variables.tf

The 'variables.tf' file sets the region to create things in, the password for the root user in the virtual machines, and the number of frontend instances.

```bash
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

variable "arm_resource_group_name" {
  description = "The name of the resource group to create."
  default     = "MehmetOsanmazRG"
}

```

## storage-account.tf

The 'storage-account.tf' file creates a storage account.

```bash
resource "azurerm_storage_account" "frontend" {
    name                     = "tf321123mehmetostracc"
    resource_group_name      = "${var.arm_resource_group_name}"
    location                 = "${var.arm_region}"
    account_tier             = "Standard"
    account_replication_type = "LRS"
}

```

## providers.tf

The 'providers.tf' file sets up the Azure provider and features.

```bash
# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

```

## output.tf

The 'output.tf' file outputs for an Azure Resource Manager (ARM) Terraform configuration. The outputs are the IDs of the frontend, backend, and DMZ subnets, as well as the IP address of the frontend public IP. These outputs can be used to display or reference important information about the resources created by the Terraform configuration. For example, you could use the output values in other parts of your Terraform configuration, or you could access the output values after running terraform apply to obtain the IDs or IP address of the resources.

```bash
output "frontend_id" {
  value = "${azurerm_subnet.my_subnet_frontend.id}"
}

output "backend_id" {
  value = "${azurerm_subnet.my_subnet_backend.id}"
}

output "dmz_id" {
  value = "${azurerm_subnet.my_subnet_dmz.id}"
}

output "load_balancer_ip" {
  value = "${azurerm_public_ip.frontend.ip_address}"
}

```

## load-balancer.tf

The load-balancer.tf file creates an Azure load balancer, a public IP address, and associated resources, using the Azure Resource Manager (ARM) provider for Terraform. The load balancer will be created in the specified resource group and location, and will be configured to use the specified public IP address. The code also defines two probes and two rules for the load balancer, on ports 80 and 443. The probes will be used to monitor the health of the backend instances, and the rules will define how traffic is distributed to the backend instances. Additionally, a backend address pool is defined for the load balancer, which will be used to specify the backend instances that the load balancer should use. This configuration will create the resources necessary to set up a load balancer in Azure, which can be used to distribute incoming traffic across multiple backend instances.

```bash
resource "azurerm_public_ip" "frontend" {
    name                         = "tf-public-ip"
    location                     = "${var.arm_region}"
    resource_group_name          = "${var.arm_resource_group_name}"
    allocation_method            = "Static"
}

resource "azurerm_lb" "frontend" {
    name                = "tf-lb"
    location            = "${var.arm_region}"
    resource_group_name = "${var.arm_resource_group_name}"
    frontend_ip_configuration {
        name                          = "default"
        public_ip_address_id          = "${azurerm_public_ip.frontend.id}"
        private_ip_address_allocation = "dynamic"
    }
}

resource "azurerm_lb_probe" "port80" {
    name                = "tf-lb-probe-80"
    loadbalancer_id     = "${azurerm_lb.frontend.id}"
    protocol            = "Http"
    request_path        = "/"
    port                = 80
}

resource "azurerm_lb_rule" "port80" {
    name                    = "tf-lb-rule-80"
    loadbalancer_id         = "${azurerm_lb.frontend.id}"
    backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.frontend.id}"]
    probe_id                = "${azurerm_lb_probe.port80.id}"
    protocol                       = "Tcp"
    frontend_port                  = 80
    backend_port                   = 80
    frontend_ip_configuration_name = "default"
}

resource "azurerm_lb_probe" "port443" {
    name                = "tf-lb-probe-443"
    loadbalancer_id     = "${azurerm_lb.frontend.id}"
    protocol            = "Http"
    request_path        = "/"
    port                = 443
}

resource "azurerm_lb_rule" "port443" {
    name                    = "tf-lb-rule-443"  
    loadbalancer_id         = "${azurerm_lb.frontend.id}"
    backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.frontend.id}"]
    probe_id                = "${azurerm_lb_probe.port443.id}"
    protocol                       = "Tcp"
    frontend_port                  = 443
    backend_port                   = 443
    frontend_ip_configuration_name = "default"
}

resource "azurerm_lb_backend_address_pool" "frontend" {
    name                = "tf-lb-pool"
    loadbalancer_id     = "${azurerm_lb.frontend.id}"
}

```

## backend.tf

backend.tf is defining the configuration for Terraform's Azure Resource Manager (azurerm) backend. The backend is used to store the state of Terraform's managed resources so that Terraform knows what has been created and what changes are necessary.

```
terraform {
    backend "azurerm" {
        storage_account_name = "mehmetosanmazacc" # Use your own unique name here
        container_name       = "terraform-sample"        # Use your own container name here
        key                  = "terraform.tfstate"       # Add a name to the state file
        resource_group_name  = "MehmetOsanmazRG"         # Use your own resource group name here
    }
}

```
#
#
#
## How to Apply the Project

Note: First you need to know that this configuration is trying to access the container named "terraform-sample" in the storage account named "mehmetosanmazacc" in the resource group named "MehmetOsanmazRG".

To resolve this issue, you will need to either create the missing resource group, storage account, and container or update the Terraform configuration to use the correct names for the existing resources. If the resources do not exist, you can create them using the Azure Portal or the Azure CLI. If the resources already exist, you can use the az group list and az storage account list commands to view the names of your resource groups and storage accounts, and then update the Terraform configuration to use the correct names.

Once you have resolved the issue with the missing resource group and storage account, you should be able to run the terraform apply command without encountering this error.

## 1. 'terraform init' command

The terraform init command is used to initialize a Terraform configuration. This is the first command that should be run after writing a new Terraform configuration or cloning an existing one from version control.

The init command performs several tasks:

It initializes a new Terraform working directory by creating a .terraform directory in the current working directory, where Terraform will store its files.

It installs any required plugins for the providers specified in the configuration. Terraform uses plugins to interact with the various infrastructure services that it manages. These plugins are usually distributed as executables, and they must be installed in the .terraform directory in order for Terraform to use them.

It downloads and installs the modules specified in the configuration. Terraform allows you to use modules to organize and reuse your Terraform code. Modules are defined using the module keyword and are downloaded from a registry, such as the Terraform Registry or a private module registry.

It downloads the provider SDKs required to manage the resource types specified in the configuration. Terraform uses provider SDKs to interact with the APIs of the various infrastructure services that it manages. These SDKs are versioned and distributed independently from Terraform itself, and they must be installed in the .terraform directory in order for Terraform to use them.

It checks for any configuration syntax errors and other problems with the configuration.

It creates an initial state file in the backend, which is used to store the current state of Terraform's managed resources. This state file is used to determine the necessary changes when running the terraform apply command.

After running terraform init, you should be ready to run the terraform plan and terraform apply commands to create and manage your infrastructure.

```bash
terraform init
```

## 2. 'terraform validate' command

The terraform validate command is used to validate the syntax of a Terraform configuration. This command checks the configuration for syntax errors, such as missing or incorrect punctuation, invalid variable references, and other issues that can prevent Terraform from running correctly.

The validate command does not create any infrastructure or modify any existing resources. It is a safe command that can be run at any time to check the validity of a configuration.

Here is an example of how to use the terraform validate command:

```bash
$ terraform validate

Success! The configuration is valid.
```
If the configuration contains any syntax errors, terraform validate will print an error message and exit with a non-zero exit code. For example:

```
$ terraform validate

Error: Invalid variable reference

  on main.tf line 5, in resource "aws_instance" "web":
   5:   ami = "${var.ami_id}"

The variable reference "var.ami_id" is not valid.
```
In this case, the ami argument for the aws_instance resource is using an invalid variable reference. The ami_id variable is not defined in the configuration, so terraform validate raises an error.

The terraform validate command is useful for catching syntax errors before running the terraform plan or terraform apply commands, which can save time and prevent potential errors or mistakes. It is a good practice to run terraform validate before running any other Terraform commands.


## 3. 'terraform plan' command. 

The terraform plan command is used to create an execution plan. Terraform performs a refresh, unless explicitly disabled, and then determines what actions are necessary to achieve the desired state specified in the configuration files. This command is important because it shows what Terraform will do when the apply command is executed, without actually making any changes to the infrastructure. This allows you to see what changes will be made, and to make any necessary adjustments to the configuration before actually applying the changes. By using the plan command, you can avoid making unintended changes to your infrastructure.

```bash
terraform plan
```

## 4. 'terraform apply' command

The terraform apply command is an essential part of the Terraform workflow. It is used to apply the changes required to reach the desired state of your infrastructure as specified in your Terraform configuration files.

When you run terraform apply, Terraform reads any configuration files you have in the current directory and prompts you to confirm the changes it is about to make to your infrastructure. This allows you to review the changes and make any necessary adjustments before applying them.

Once you confirm the changes, Terraform will execute the necessary actions to make the changes, such as creating new resources or modifying existing ones. This process is similar to what happens when you run the terraform plan command but terraform apply actually makes the changes, rather than just showing you what changes will be made.

The terraform apply command is typically used after you have run terraform plan to preview the changes that will be made to your infrastructure. This allows you to see what changes Terraform will make before actually making them, giving you an opportunity to make any necessary adjustments to your configuration.

In summary, the terraform apply command is a key part of the Terraform workflow, and is used to apply the changes required to reach the desired state of your infrastructure as specified in your Terraform configuration files. It allows you to review the changes before making them and is used to make the actual changes to your infrastructure.
```bash
terraform apply
```

## 5. 'terraform state list' command

The terraform state list command is used to list the resources that are managed by Terraform. This command can be useful for getting an overview of the resources that are currently being managed by Terraform, or for troubleshooting issues with your Terraform configuration.

When you run terraform state list, Terraform reads the state file for the current directory and outputs a list of the resources that are being managed by Terraform. This list includes the type of each resource, as well as its unique identifier within the state file.

The terraform state list command can be used in conjunction with other Terraform commands to manage and manipulate your infrastructure. For example, you could use the output of this command with the terraform state show command to view detailed information about a specific resource, or with the terraform state rm command to remove a resource from the state file.

In summary, the terraform state list command is used to list the resources that are being managed by Terraform. This command can be useful for getting an overview of your infrastructure, or for troubleshooting issues with your Terraform configuration.

```bash
terraform state list
```

## 6. 'terraform destroy' command

The terraform destroy command is used to destroy the infrastructure that was created with Terraform. This command is the opposite of terraform apply, which is used to create and manage infrastructure.

When you run terraform destroy, Terraform reads any configuration files you have in the current directory and prompts you to confirm the destruction of the infrastructure. Once you confirm the destruction, Terraform will execute the necessary actions to destroy the infrastructure, such as deleting resources or modifying existing ones to remove their association with the infrastructure.

The terraform destroy command is typically used when you no longer need the infrastructure that was created with Terraform, or when you want to start over from scratch. This command can save you time and resources by allowing you to quickly and easily destroy infrastructure that is no longer needed.

In summary, the terraform destroy command is used to destroy the infrastructure that was created with Terraform. It is the opposite of terraform apply, and allows you to quickly and easily destroy infrastructure that is no longer needed.

```bash
terraform destroy
```

