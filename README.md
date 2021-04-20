# Terraform AWS Maintenance Mode API module

> Terraform modules which creates API Gateway resources on AWS.

![Terraform GitHub Actions](https://github.com/edithcare/terraform-aws-maintenance-mode-api/workflows/Terraform%20GitHub%20Actions/badge.svg)

## available features

- module creates a Maintenance Mode API on AWS through the AWS API Gateway and all necessary resource like custom domains in Route53. - It's possible to declare multiple different environments with specific endpoints and separate maintenance mode toggles.
- endpoint will return a HTTP status code 200 in case the maintenance mode is off, otherwise a 503 HTTP status code for all requests.


## usage
```hcl
module "maintenance_api" {
  source  = "app.terraform.io/edithcare/maintenance-mode-api/aws"
  version = "0.1.0"

  zone_name                = "test.com."
  maintenance_api_name     = "Maintenance API"
  certificate_domain_names = ["test-maintenance-api.test.com", "test-maintenance-api-dev.test.com"]

  environments = {
    "dev"  = "test-maintenance-api-dev.test.com"
    "prod" = "test-maintenance-api.test.com"
  }

  maintenance_modes = {
    "dev"  = true
    "prod" = false
  }
}
```

## conditional creation
..

# examples
- [simple](examples/simple): simple usage ..

## documentation

Terraform documentation is generated automatically using [pre-commit hooks](http://www.pre-commit.com/). Follow installation instructions [here](https://pre-commit.com/#install).

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 0.14.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.30.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.30.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.maintenance_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.maintenance_api_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_api_gateway_base_path_mapping.public_domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_base_path_mapping.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.restapi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name.public_domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
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
| [aws_route53_zone.name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificate_domain_names"></a> [certificate\_domain\_names](#input\_certificate\_domain\_names) | The domain name which should be part of the new SSL ACM certificate | `list(string)` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | main url for the maintenance api endpoint | `string` | n/a | yes |
| <a name="input_environments"></a> [environments](#input\_environments) | environment to its final HTTPS endpoint https://api-maintenance.test.com | `string` | n/a | yes |
| <a name="input_maintenance_api_name"></a> [maintenance\_api\_name](#input\_maintenance\_api\_name) | The name AWS API Gateway | `string` | n/a | yes |
| <a name="input_maintenance_modes"></a> [maintenance\_modes](#input\_maintenance\_modes) | true indicates environment is in maintenance mode | `bool` | n/a | yes |
| <a name="input_template"></a> [template](#input\_template) | mailto email address for html template | `map(string)` | <pre>{<br>  "mailto": "MAILTO",<br>  "team": "TEAM"<br>}</pre> | no |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | The name of the DNS zone | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_api_gateway_domain_names"></a> [aws\_api\_gateway\_domain\_names](#output\_aws\_api\_gateway\_domain\_names) | The map with a mapping from environment to its associated API Gateway endpoint. |


## license

MIT Licensed. See [LICENSE](https://github.com/edithcare/terraform-aws-maintenance-mode-api/blob/master/LICENSE) for full details.
