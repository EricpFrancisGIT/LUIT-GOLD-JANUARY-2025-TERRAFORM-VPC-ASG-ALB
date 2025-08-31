variable "datadog_api_key" {
  type      = string
  sensitive = true
}
variable "datadog_app_key" {
  type      = string
  sensitive = true
}
variable "datadog_site" {
  type    = string
  default = "datadoghq.com" # us: datadoghq.com, eu: datadoghq.eu, us3: us3.datadoghq.com, us5: us5.datadoghq.com, gov: ddog-gov.com
}
