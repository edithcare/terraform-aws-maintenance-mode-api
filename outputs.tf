output "aws_api_gateway_domain_name" {
  value       = aws_api_gateway_domain_name.public_domain
  description = "needed at aws_route53_record alias (regional_domain_name and regional_zone_id)"
}
