
output "instances" {
  description = <<-EOT
  An object mapping the availability zone in use to the instance ID for the created EC2 instance running EOTK in that
  availability zone.
  EOT
  value = {
    for i in range(var.instance_count) : data.aws_availability_zones.available.names[i] => module.instance[i].id
  }
}

output "log_bucket_id" {
  description = <<-EOT
  The ID of the log bucket created to hold the nginx access logs.
  EOT
  value       = module.conf_log.log_bucket_id
}

output "log_bucket_arn" {
  description = <<-EOT
  The ARN of the log bucket created to hold the nginx access logs.
  EOT
  value       = module.conf_log.log_bucket_arn
}