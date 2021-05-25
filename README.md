# Terraform AWS Maintenance Mode API module

> terraform module which creates AWS API Gateway and Route53 resources for a maintenancenmode

![Terraform GitHub Actions](https://github.com/edithcare/terraform-aws-maintenance-mode-api/workflows/Terraform%20GitHub%20Actions/badge.svg)

- creates API Gateway mock for toggling maintenance mode (`ON`/`OFF`)
- API Gateway endpoint will return a HTTP status `200` if maintenance mode is `OFF` or `503` when maintenance is `ON` for `GET` and `OPTIONS`
- `GET` returns a static maintenance html
- can add additional route53 weighted records that point to API Gateway and other Location


# examples
- [simple](examples/simple) mvp example for module usage

## documentation

documentation is generated via `terraform-docs markdown .`


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 0.14.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.42.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.42.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.maintenance_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.maintenance_api_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_api_gateway_base_path_mapping.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
| [aws_api_gateway_integration.get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration_response.get_response_200](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_integration_response.get_response_503](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_integration_response.options_response_200](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_method.get](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_response.get_response_200](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_response.get_response_503](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_response.options_response_200](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_rest_api.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_route53_record.maintenance_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.maintenance_api_cert_validations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_api_gateway_resource.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/api_gateway_resource) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_domain_name"></a> [api\_domain\_name](#input\_api\_domain\_name) | main url for the maintenance api endpoint | `string` | n/a | yes |
| <a name="input_api_name"></a> [api\_name](#input\_api\_name) | name of api-gateway | `string` | n/a | yes |
| <a name="input_api_stage_name"></a> [api\_stage\_name](#input\_api\_stage\_name) | stage\_name point so api endpoint | `string` | n/a | yes |
| <a name="input_html_template"></a> [html\_template](#input\_html\_template) | mailto email address for html template | `map(string)` | <pre>{<br>  "mailto": "MAILTO",<br>  "team": "TEAM"<br>}</pre> | no |
| <a name="input_maintenance_modes"></a> [maintenance\_modes](#input\_maintenance\_modes) | true indicates environment is in maintenance mode | `bool` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | map of tags passed into module | `map(string)` | `{}` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | aws route 53 zone id | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | id of the API to connect |
| <a name="output_stage_name"></a> [stage\_name](#output\_stage\_name) | name of a specific deployment stage to expose at the given path |

## license

MIT Licensed. See [LICENSE](https://github.com/edithcare/terraform-aws-maintenance-mode-api/blob/master/LICENSE) for full details.
