variable "unifi_url" {
  type        = string
  description = "UniFi OS console URL, without /api or /proxy/network"
  default     = "https://unifi.sklab.dev"
}

# WPA passphrases. The controller never returns them to the read-only role, so
# they are owned by 1Password and only matter on create or after a deliberate
# change; each wlan carries ignore_changes on passphrase.
variable "wlan_passphrase_home" {
  type        = string
  description = "WPA passphrase of the U7-Home SSID"
  sensitive   = true
}

variable "wlan_passphrase_iot" {
  type        = string
  description = "WPA passphrase of the U7-IOT SSID"
  sensitive   = true
}

variable "wlan_passphrase_secure" {
  type        = string
  description = "WPA passphrase of the U7-Secure SSID"
  sensitive   = true
}

variable "state_passphrase" {
  type        = string
  description = "Passphrase for OpenTofu state and plan encryption (pbkdf2, aes_gcm). 1Password owns it; losing it means rebuilding state from imports.tofu."
  sensitive   = true
}
