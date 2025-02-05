variable "instance_count" {
  description = <<EOT
  Number of EC2 instances to create. If the number specified is more than the number of available availability zones,
  the number of instances will be capped to the number of available availability zones. If the number is zero then no
  instances will be created.
  EOT
  default     = 2
  type        = number
  validation {
    condition     = var.instance_count >= 0
    error_message = "The number of instances must be positive."
  }
}

variable "configuration_bundle" {
  description = <<EOT
  Path to the zip file that contains the configuration bundle to be uploaded to the configuration bucket.
  EOT
  type        = string
}
