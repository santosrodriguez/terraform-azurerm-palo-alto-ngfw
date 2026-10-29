# Palo Alto Cloud NGFW Virtual Hub Panorama

This module deploys a Panorama-managed Cloud NGFW, registers its virtual network appliance, and configures virtual hub routing intent for Internet and private traffic. Public IPs are managed by the caller.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `public_ip_address_ids` | `list(string)` | Required | Non-null list of at least one public IP resource ID. |
| `egress_nat_ip_address_ids` | `list(string)` | `[]` | Public IP resource IDs used for outbound SNAT. |
| `panorama_base64_config` | `string` | Required | Sensitive Panorama onboarding configuration. |
| `resource_group_name` | `string` | Required | Resource group for Palo Alto resources. |
| `location` | `string` | Required | US Azure region allowed by variables.tf. |
| `virtual_hub_id` | `string` | Required | Existing Virtual WAN hub ID. |
| `enable_internet_routing_intent` | `bool` | `true` | Route Internet traffic through the Palo Alto appliance. |
| `enable_private_routing_intent` | `bool` | `true` | Route private traffic through the Palo Alto appliance. |
| `environment` | `string` | Required | `prd` or `nonprd`. |
| `solution_name` | `string` | `"vhub"` | Solution name used in resource names. |
| `plan_id` | `string` | `"panw-cngfw-payg"` | Marketplace plan ID. |
| `tags` | `map(string)` | `{}` | Tags merged with module defaults. |

Requires Terraform `>= 1.1.0`, AzureRM `>= 4.50.0`, an existing resource group and virtual hub, public IPs, and permissions to deploy the firewall, appliance, and routing intent.

## Caller configuration

Adjust names, region, zones, and tags for your environment. The source path is relative to the calling configuration.

```hcl
locals {
  firewall_public_ips = {
    pip01 = "pip-pangfw-vhub-eastus-prd-01"
    pip02 = "pip-pangfw-vhub-eastus-prd-02"
  }
}

resource "azurerm_public_ip" "ngfw" {
  for_each = local.firewall_public_ips

  name                = each.value
  resource_group_name = var.resource_group_name
  location            = "eastus"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

module "palo_alto_cloud_ngfw_vhub" {
  source = "./palo-alto-ngfw"

  public_ip_address_ids = [for pip in azurerm_public_ip.ngfw : pip.id]
  panorama_base64_config = var.panorama_base64_config
  resource_group_name    = var.resource_group_name
  location               = "eastus"
  virtual_hub_id         = var.virtual_hub_id
  environment            = "prd"
  tags                   = var.tags
}
```

For one separately declared IP, use `public_ip_address_ids = [azurerm_public_ip.ngfw.id]`. Resource references establish dependencies automatically.

Set either routing intent input to `false` in the module call to disable that traffic policy independently. For example, to retain Internet routing intent and disable private routing intent:

```hcl
  enable_internet_routing_intent = true
  enable_private_routing_intent  = false
```

Setting both inputs to `false` removes the routing intent resource and returns `null` for `routing_intent_id`. This does not configure replacement routes; traffic follows the remaining hub routing configuration.

## Outputs

| Name | Description |
|---|---|
| `firewall_id` | Palo Alto Cloud NGFW resource ID. |
| `routing_intent_id` | Routing intent resource ID, or `null` when both policies are disabled. |
| `public_ip_ids` | Public IP IDs supplied by the caller, retained for compatibility. |

## Migration

Remove `public_ip_count` and `public_ip_zones` from module calls and supply `public_ip_address_ids`. Configure zones on the caller-managed IP resources.

For existing IPs in the same Terraform state, add one `moved` block per IP to the calling root module. Adjust the module address and keys to match your deployment:

```hcl
moved {
  from = module.palo_alto_cloud_ngfw_vhub.azurerm_public_ip.ngfw[0]
  to   = azurerm_public_ip.ngfw["pip01"]
}

moved {
  from = module.palo_alto_cloud_ngfw_vhub.azurerm_public_ip.ngfw[1]
  to   = azurerm_public_ip.ngfw["pip02"]
}
```

Preserve existing IP names, resource groups, regions, allocation methods, SKUs, zones, and tags in the new configuration. Address moves do not prevent replacement caused by changed arguments. Review the plan to confirm IPs move without destruction or replacement and their IDs stay unchanged. Cross-state moves require a separate state migration.

## Behavior

- Resource names include the solution, location, environment, and a random numeric suffix.
- Default tags are `Managed_by = "Terraform"`, `platform = "Network"`, and `Owner = "Cloud Platform Team"`. Caller tags override matching defaults. Resource lifecycle settings ignore subsequent tag changes.
- Routing intent sends enabled traffic types (`Internet` and/or `PrivateTraffic`) to the Palo Alto appliance and waits for firewall creation. Both are enabled by default; no routing intent resource is created when both are disabled.
- Protect the sensitive Panorama configuration and use protected remote state.
