# This file was generated by symflow CLI v8.0.2 on 2023-08-08 at 13:23 UTC.
# No changes to this file are required to start managing your Okta access with Sym.
# Modify this file to customize your Okta access management, or add more Okta Groups to be managed.


# The Okta Integration that your Sym Strategy uses to manage your Okta targets
resource "sym_integration" "access_okta" {
  type        = "okta"
  name        = "access-okta-integration"
  external_id = "sym-demo.okta.com"

  settings = {
    # `type=okta` sym_integrations have a required setting `api_token_secret`,
    # which must point to a sym_secret referencing your Okta API Key
    api_token_secret = sym_secret.access_okta_api_key.id
  }
}

# An AWS Secrets Manager Secret to hold your Okta API Key. Set the value with:
# aws secretsmanager put-secret-value --secret-id "sym/okta-access/okta-api-key" --secret-string "YOUR-OKTA-API-KEY"
resource "aws_secretsmanager_secret" "access_okta_api_key" {
  name        = "sym/okta-access/okta-api-key"
  description = "API Key for Sym to call Okta APIs"

  tags = {
    # This SymEnv tag is required because the secrets_manager_access module defined in secrets.tf
    # only grants access to secrets tagged with a SymEnv value that matches its `environment` input variable.
    SymEnv = local.environment_name
  }
}

# This resource tells Sym how to access your Okta API Key.
resource "sym_secret" "access_okta_api_key" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  source_id = sym_secrets.this.id

  # Name of the key in AWS Secrets Manager
  path = aws_secretsmanager_secret.access_okta_api_key.name
}

# A target Okta group that your Sym Strategy can manage access to
resource "sym_target" "okta_group_1" {
  type  = "okta_group"
  name  = "okta-admin-group"
  label = "Okta Admin Group"

  settings = {
    # `type=okta_group` sym_targets have a required setting `group_id`,
    # which must be the Group ID the requester will be escalated to when this target is selected.

    # The GroupID is visible while in the Okta Admin console, with the Group selected, in the URL of the browser.
    # Directory > Groups > Select the Group > the ID at the end of the browser's URL.
    group_id = "00g12345abc"
  }
}

# A target Okta group that your Sym Strategy can manage access to
resource "sym_target" "okta_group_2" {
  type  = "okta_group"
  name  = "okta-staging-access-group"
  label = "Okta Staging Access Group"

  settings = {
    # `type=okta_group` sym_targets have a required setting `group_id`,
    # which must be the Group ID the requester will be escalated to when this target is selected.

    # The GroupID is visible while in the Okta Admin console, with the Group selected, in the URL of the browser.
    # Directory > Groups > Select the Group > the ID at the end of the browser's URL.
    group_id = "00g00000abc"
  }
}

# The Strategy your Flow uses to escalate to Okta Groups
resource "sym_strategy" "access_okta" {
  type           = "okta"
  name           = "access-okta-strategy"
  integration_id = sym_integration.access_okta.id

  # This must be a list of `okta_group` sym_target that users can request to be escalated to
  targets = [sym_target.okta_group_1.id, sym_target.okta_group_2.id]
}

resource "sym_flow" "access_okta" {
  name  = "access-okta"
  label = "Okta Access"

  implementation = file("${path.module}/impls/okta_access_impl.py")
  environment_id = sym_environment.this.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.access_okta.id

    # Each prompt_field defines a custom form field for the Slack modal that
    # requesters fill out to make their requests.
    prompt_field {
      name     = "reason"
      label    = "Why do you need access?"
      type     = "string"
      required = true
    }

    prompt_field {
      name           = "duration"
      type           = "duration"
      allowed_values = ["30m", "1h"]
      required       = true
    }
  }
}
