locals {
  username = "az-admin"
}

resource "azurerm_resource_group" "hnt_rg" {
  location = var.az_region
  name     = var.az_resource_group_name
}

# Create virtual network
resource "azurerm_virtual_network" "hnt_terraform_network" {
  name                = "${var.az_resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.hnt_rg.location
  resource_group_name = azurerm_resource_group.hnt_rg.name
}

# Create subnet
resource "azurerm_subnet" "hnt_terraform_subnet" {
  name                 = "${var.az_resource_group_name}-subnet"
  resource_group_name  = azurerm_resource_group.hnt_rg.name
  virtual_network_name = azurerm_virtual_network.hnt_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "hnt_terraform_public_ip" {
  name                = "${var.az_resource_group_name}-public-ip"
  location            = azurerm_resource_group.hnt_rg.location
  resource_group_name = azurerm_resource_group.hnt_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "hnt_terraform_nsg" {
  name                = "${var.az_resource_group_name}-nsg"
  location            = azurerm_resource_group.hnt_rg.location
  resource_group_name = azurerm_resource_group.hnt_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "AltSSH"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.ssh_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "hnt_terraform_nic" {
  name                = "${var.az_resource_group_name}-nic"
  location            = azurerm_resource_group.hnt_rg.location
  resource_group_name = azurerm_resource_group.hnt_rg.name

  ip_configuration {
    name                          = "hnt_nic_configuration"
    subnet_id                     = azurerm_subnet.hnt_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hnt_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.hnt_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.hnt_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.hnt_rg.name
  }

  byte_length = 8
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "hnt_terraform_vm" {
  name                  = var.az_vm_name
  location              = azurerm_resource_group.hnt_rg.location
  resource_group_name   = azurerm_resource_group.hnt_rg.name
  network_interface_ids = [azurerm_network_interface.hnt_terraform_nic.id]
  size                  = var.az_vm_size
  
  os_disk {
    name                 = "hntOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-25_04"
    sku       = "minimal"
    version   = "latest"
  }

  computer_name  = "hnt-prod-server"
  admin_username = local.username

  admin_ssh_key {
    username   = local.username
    public_key = sensitive(file(var.az_pub_ssh_key_file))
  }

  # Enable system assigned managed identity for blob storage access
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_account" "hnt_storage_acc" {
  name                     = "hacknocturne" # need to be globally unique
  resource_group_name      = azurerm_resource_group.hnt_rg.name
  location                 = azurerm_resource_group.hnt_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "hnt_storage_blob" {
  name                  = "opa"
  storage_account_id    = azurerm_storage_account.hnt_storage_acc.id
  container_access_type = "private"
}

# Role assignment for OPA to read blobs
resource "azurerm_role_assignment" "opa_blob_reader" {
  scope                = azurerm_storage_account.hnt_storage_acc.id
  role_definition_name = "Storage Blob Data Reader"

  # bind the VM's system-assigned identity
  principal_id = azurerm_linux_virtual_machine.hnt_terraform_vm.identity[0].principal_id
}
