variable "cluster_name" {
  type = "string"
}

variable "agent_vm_count" {
  type    = "string"
  default = "3"
}

variable "dns_prefix" {
  type = "string"
}

variable "ssh_public_key" {
  type = "string"
}

variable "service_principal_is_owner" {
    type = "string"
    default = "1"
}

variable "service_principal_id" {
  type = "string"
}

variable "service_principal_secret" {
  type = "string"
}

variable "gitops_ssh_url" {
  type = "string"
}

variable "gitops_poll_interval" {
  type = "string"
}
variable "gitops_ssh_key" {
  type = "string"
}

variable "aks_client_role_assignment_role" {
  type    = "string"
  default = "Contributor"
}

<<<<<<< HEAD
variable "subscription_id" {
  type = "string"
}

variable "tenant_id" {
  type = "string"
}

=======
>>>>>>> 97590d70e78cb66420a10bcb742868c4a878f946
variable "flux_recreate" {
    description = "Make any change to this value to trigger the recreation of the flux execution script."
    type = "string"
    default = ""
}