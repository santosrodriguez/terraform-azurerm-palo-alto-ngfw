

variable "enable_internet_routing_intent" {
  description = "Enable routing intent to send Internet traffic to the Palo Alto appliance."
  type        = bool
  default     = true
  nullable    = false
}

variable "enable_private_routing_intent" {
  description = "Enable routing intent to send private traffic to the Palo Alto appliance."
  type        = bool
  default     = true
  nullable    = false
}

variable "public_ip_address_ids" {
  description = "Public IP resource IDs to associate with Palo Alto Cloud NGFW. Public IPs are managed outside this module."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.public_ip_address_ids) > 0
    error_message = "Provide at least one public IP resource ID."
  }
}





variable "egress_nat_ip_address_ids" {
  description = "Public IP resource IDs used for outbound SNAT."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "panorama_base64_config" {
  description = "Base64 Panorama onboarding string generated from Panorama."
  type        = string
  sensitive   = true
}


variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "Resource group name for Palo Alto resources."
  type        = string
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment. Only US regions are allowed."

  validation {
    condition = contains([
      "eastus",
      "eastus2",
      "centralus",
      "northcentralus",
      "southcentralus",
      "westcentralus",
      "westus",
      "westus2",
      "westus3"
    ], lower(var.location))

    error_message = "Location must be a valid Azure US region: eastus, eastus2, centralus, northcentralus, southcentralus, westcentralus, westus, westus2, or westus3."
  }
}

variable "virtual_hub_id" {
  description = "ID of the Virtual WAN Hub."
  type        = string
}

variable "environment" {
  type = string
  validation {
    condition = contains(
      ["prd", "nonprd"], var.environment
    )
    error_message = "Error: Valid environments are prd and nonprd"
  }
}

variable "solution_name" {
  type    = string
  default = "vhub"
}

variable "plan_id" {
  description = "Plan ID for the Palo Alto Cloud NGFW."
  type        = string
  default     = "panw-cngfw-payg"
}
