variable "api_name" {
  type        = string
  description = "name of api-gateway"
}

variable "api_stage_name" {
  type        = string
  description = "stage_name point so api endpoint"
}

variable "api_domain_name" {
  type        = string
  description = "main url for the maintenance api endpoint"
}

variable "public_domains" {
  type        = map(string)
  description = "public domains that point to api-gateway"
}

variable "zone_id" {
  type        = string
  description = "aws route 53 zone id"
}

variable "maintenance_modes" {
  type        = bool
  description = "true indicates environment is in maintenance mode"
}

variable "html_template" {
  type        = map(string)
  description = "mailto email address for html template"
  default     = { "mailto" = "MAILTO", "team" = "TEAM" }
}

variable "tags" {
  type        = map(string)
  description = "map of tags passed into module"
  default     = {}
}
