variable "maintenance_api_name" {
  type        = string
  description = "The name AWS API Gateway"
}

variable "certificate_domain_names" {
  type        = list(string)
  description = "The domain name which should be part of the new SSL ACM certificate"
}

variable "zone_name" {
  type        = string
  description = "The name of the DNS zone"
}

variable "environments" {
  type        = map(string)
  description = "Mapping of environment to its final HTTPS endpoint - e.q. {dev: https://api-maintenance.test.com}"
}

variable "maintenance_modes" {
  type        = map(bool)
  description = "Mapping of environment to its current maintenance mode; true indicates environment is in maintenance mode - e.q. {dev: true}"
}
