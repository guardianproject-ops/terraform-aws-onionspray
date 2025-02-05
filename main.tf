locals {
  instance_count = module.this.enabled ? min(var.instance_count, length(data.aws_availability_zones.available)) : 0
}

module "conf_log" {
  source  = "sr2c/ec2-conf-log/aws"
  version = "0.0.8"
  context = module.this.context

}

module "instance" {
  source  = "cloudposse/ec2-instance/aws"
  version = "1.6.1"
  count   = local.instance_count

  subnet                        = data.aws_subnet.default[count.index].id
  vpc_id                        = data.aws_vpc.default.id
  ami                           = data.aws_ami.ubuntu.id
  ami_owner                     = "099720109477"
  assign_eip_address            = true
  associate_public_ip_address   = true
  disable_api_termination       = false
  instance_type                 = "t3.medium"
  instance_profile              = module.conf_log.instance_profile_name
  metadata_http_tokens_required = true
  user_data_base64              = data.cloudinit_config.this.rendered

  context    = module.this.context
  attributes = [tostring(count.index)]

  depends_on = [module.conf_log]
}

resource "aws_s3_object" "configuration_bundle" {
  bucket = module.conf_log.conf_bucket_id
  key    = "configuration.zip"
  source = var.configuration_bundle
  etag   = filemd5(var.configuration_bundle)
}
