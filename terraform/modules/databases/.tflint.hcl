# TFLint configuration for Open Horizons Platform

config {
  force = false
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Disable unused declarations check - variables are for future use
rule "terraform_unused_declarations" {
  enabled = false
}

# Disable required_providers check - provider versions are managed centrally
rule "terraform_required_providers" {
  enabled = false
}
