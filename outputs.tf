output "aws_api_gateway_domain_names" {
  description = "The map with a mapping from environment to its associated API Gateway endpoint."
  value = {
    domain_name = aws_api_gateway_domain_name.restapi.regional_domain_name
    zone_id     = aws_api_gateway_domain_name.restapi.regional_zone_id
  }
}
