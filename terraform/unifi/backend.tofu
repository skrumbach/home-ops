# Local state until the R2 backend lands. terraform/.gitignore keeps *.tfstate
# out of Git and scripts/ci/tofu-validate.sh refuses a committed one.
# The state holds object IDs and MACs, not WiFi passphrases (the read-only role
# cannot see them and passphrase is ignore_changes), but never commit it.
# Skill `unifi-network`.
terraform {
  backend "local" {}
}
