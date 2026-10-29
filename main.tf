locals {
  default_tags = {
    Managed_by = "Terraform"
    platform   = "Network"
    Owner      = "Cloud Platform Team"
  }
  name_suffix = "${var.solution_name}-${var.location}-${var.environment}-${random_string.this.result}"

  tags = merge(
    local.default_tags,
    var.tags
  )
}

resource "random_string" "this" {
  length  = 4
  upper   = false
  lower   = false
  special = false
  numeric = true
}


###############################################################
# Palo Alto Virtual Network Appliance Registration
###############################################################

resource "azurerm_palo_alto_virtual_network_appliance" "this" {
  name           = "panva-${local.name_suffix}"
  virtual_hub_id = var.virtual_hub_id


}

###############################################################
# Palo Alto Cloud NGFW SaaS - Panorama Managed
###############################################################

resource "azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama" "this" {
  name                = "pangfw-${local.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  panorama_base64_config = var.panorama_base64_config

  network_profile {
    public_ip_address_ids = var.public_ip_address_ids

    virtual_hub_id = var.virtual_hub_id

    network_virtual_appliance_id = azurerm_palo_alto_virtual_network_appliance.this.id
    egress_nat_ip_address_ids    = var.egress_nat_ip_address_ids
  }
  plan_id = var.plan_id

  tags = local.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

###############################################################
# Routing Intent
###############################################################

resource "azurerm_virtual_hub_routing_intent" "this" {
  count = var.enable_internet_routing_intent || var.enable_private_routing_intent ? 1 : 0

  name           = "rtintent-${local.name_suffix}"
  virtual_hub_id = var.virtual_hub_id

  dynamic "routing_policy" {
    for_each = var.enable_internet_routing_intent ? [1] : []

    content {
      name         = "InternetTrafficPolicy"
      destinations = ["Internet"]
      next_hop     = azurerm_palo_alto_virtual_network_appliance.this.id
    }
  }

  dynamic "routing_policy" {
    for_each = var.enable_private_routing_intent ? [1] : []

    content {
      name         = "PrivateTrafficPolicy"
      destinations = ["PrivateTraffic"]
      next_hop     = azurerm_palo_alto_virtual_network_appliance.this.id
    }
  }

  depends_on = [azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama.this]
}
