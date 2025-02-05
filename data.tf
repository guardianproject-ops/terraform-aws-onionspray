data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  count             = local.instance_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  default_for_az    = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "cloudinit_config" "this" {
  base64_encode = true
  gzip          = true

  part {
    content = templatefile("${path.module}/templates/user_data.yaml", {
      configure_script = jsonencode(templatefile("${path.module}/templates/configure.sh",
      { bucket_name = module.conf_log.conf_bucket_id })),
      logrotate_script = jsonencode(templatefile("${path.module}/templates/logrotate",
      { bucket_name = module.conf_log.log_bucket_id })),
      crontab = jsonencode(file("${path.module}/templates/cron"))
    })
    content_type = "text/cloud-config"
    filename     = "user_data.yaml"
  }
}
