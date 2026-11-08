variable "truenas_endpoint" {
  type        = string
  description = "TrueNAS JSON-RPC WebSocket endpoint"
  default     = "wss://nas.sklab.dev/api/current"
}

variable "state_passphrase" {
  type        = string
  description = "Passphrase for OpenTofu state and plan encryption (pbkdf2, aes_gcm). 1Password owns it; losing it means rebuilding state from imports.tofu."
  sensitive   = true
}
