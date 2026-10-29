output "firewall_id" {
  value = azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama.this.id
}

output "routing_intent_id" {
  description = "Routing intent resource ID, or null when both routing intent policies are disabled."
  value       = try(azurerm_virtual_hub_routing_intent.this[0].id, null)
}

output "public_ip_ids" {
  description = "Public IP resource IDs supplied to the firewall module."
  value       = var.public_ip_address_ids
}
