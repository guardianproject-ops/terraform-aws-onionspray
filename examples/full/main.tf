
module "onionspray" {
  source               = "../../"
  namespace            = "eg"
  name                 = "onionspray"
  instance_count       = 1
  configuration_bundle = "keys/configuration.zip"
}
