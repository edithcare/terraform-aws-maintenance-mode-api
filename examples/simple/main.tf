module "maintenance_api" {
  source = "../../"

  zone_name                = "simple.com."
  maintenance_api_name     = "Maintenance API"
  certificate_domain_names = ["simple-maintenance-api.simple.com", "simple-maintenance-api-dev.simple.com"]

  environments = {
    "dev"  = "simple-maintenance-api-dev.simple.com"
    "prod" = "simple-maintenance-api.simple.com"
  }

  maintenance_modes = {
    "dev"  = true
    "prod" = false
  }
}
