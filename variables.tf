variable "maintenance_api_name" {
  type        = string
  description = "The name AWS API Gateway"
}

variable "certificate_domain_names" {
  type        = list(string)
  description = "The domain name which should be part of the new SSL ACM certificate"
}

variable "domain_name" {
  type        = string
  description = "main url for the maintenance api endpoint"
}

variable "zone_name" {
  type        = string
  description = "The name of the DNS zone"
}

variable "environments" {
  type        = string
  description = "environment to its final HTTPS endpoint https://api-maintenance.test.com"
}

variable "maintenance_modes" {
  type        = bool
  description = "true indicates environment is in maintenance mode"
}

variable "template" {
  type        = map(string)
  default     = { "mailto" = "MAILTO", "team" = "TEAM" }
  description = "mailto email address for html template"
}
