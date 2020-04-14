output environments {
  description = "The map with created environments."
  value       = var.environments
}

output aws_api_gateway_domain_names {
  description = "The map with a mapping from environment to its associated API Gateway endpoint."
  value = {
    for environment in keys(var.environments) :
    environment => {
      domain_name = aws_api_gateway_domain_name.maintenance_api[environment].regional_domain_name
      zone_id     = aws_api_gateway_domain_name.maintenance_api[environment].regional_zone_id
    }
  }
}
