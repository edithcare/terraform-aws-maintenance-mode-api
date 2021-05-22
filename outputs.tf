output "api_id" {
  value       = aws_api_gateway_rest_api.restapi.id
  description = "id of the API to connect"
}

output "stage_name" {
  value       = aws_api_gateway_stage.restapi.stage_name
  description = "name of a specific deployment stage to expose at the given path"
}
