# The OneLogin Integration that your Sym Strategy uses to manage your OneLogin targets
resource "sym_integration" "access_onelogin" {
  type        = "onelogin"
  name        = "access-onelogin-integration"
  external_id = "sym-demo.onelogin.com"

  settings = {
    # `type=onelogin` sym_integrations have a required settings `client_id` and `client_secret`.
    # These must be set to the values of a OneLogin API Credential Pair with "Manage All" permissions.
    # See: https://docs.symops.com/docs/onelogin#create-a-onelogin-api-user-and-credentials

    # This must be set to the Client ID of a OneLogin API Credential Pair.
    client_id = "1234567890clientId"

    # This  must be set to the ID of a sym_secret referencing your OneLogin API Credential Pair's Client Secret.
    client_secret = sym_secret.access_onelogin_client_secret.id
  }
}

# An AWS Secrets Manager Secret to hold your OneLogin Client Secret. Set the value with:
# aws secretsmanager put-secret-value --secret-id "sym/onelogin-access/onelogin-client-secret" --secret-string "YOUR-ONELOGIN-CLIENT-SECRET"
resource "aws_secretsmanager_secret" "access_onelogin_client_secret" {
  name        = "sym/onelogin-access/onelogin-client-secret"
  description = "The Client Secret of the API Credential Pair for Sym to call OneLogin APIs"

  tags = {
    # This SymEnv tag is required because the secrets_manager_access module defined in secrets.tf
    # only grants access to secrets tagged with a SymEnv value that matches its `environment` input variable.
    SymEnv = local.environment_name
  }
}

# This resource tells Sym how to access your OneLogin Client Secret.
resource "sym_secret" "access_onelogin_client_secret" {
  # The source of your secrets and the permissions needed to access
  # i.e. AWS Secrets Manager, access with IAM Role.
  source_id = sym_secrets.this.id

  # Name of the key in AWS Secrets Manager
  path = aws_secretsmanager_secret.access_onelogin_client_secret.name
}

# A target OneLogin role that your Sym Strategy can manage access to
resource "sym_target" "onelogin_admin_role" {
  type = "onelogin_role"
  name = "onelogin-admin-role"
  label = "Admin Role"

  settings = {
    # `type=onelogin_role` sym_targets have the required settings `role_id` and `privilege_level`,
    # where `role_id` must be the ID of the role the requester will be escalated to when this target is selected,
    # and `privilege_level` must be one of 'member' or 'admin', indicating the privileges to grant the requester in the role.

    # The Role ID can be found in the URL when viewing the Role details
    # (Admin Console > Users > Roles > Select your Role).
    role_id = "123467"
    privilege_level = "member"
  }
}

# A target OneLogin role that your Sym Strategy can manage access to
resource "sym_target" "onelogin_customer_success_role" {
  type = "onelogin_role"
  name = "onelogin-customer-success-role"
  label = "Customer Success Role"

  settings = {
    # `type=onelogin_role` sym_targets have the required settings `role_id` and `privilege_level`,
    # where `role_id` must be the ID of the role the requester will be escalated to when this target is selected,
    # and `privilege_level` must be one of 'member' or 'admin', indicating the privileges to grant the requester in the role.

    # The Role ID can be found in the URL when viewing the Role details
    # (Admin Console > Users > Roles > Select your Role).
    role_id = "789012"
    privilege_level = "member"
  }
}

# A target OneLogin role that your Sym Strategy can manage access to
resource "sym_target" "onelogin_power_user_role" {
  type = "onelogin_role"
  name = "onelogin-power-user-role"
  label = "Power User Role"

  settings = {
    # `type=onelogin_role` sym_targets have the required settings `role_id` and `privilege_level`,
    # where `role_id` must be the ID of the role the requester will be escalated to when this target is selected,
    # and `privilege_level` must be one of 'member' or 'admin', indicating the privileges to grant the requester in the role.

    # The Role ID can be found in the URL when viewing the Role details
    # (Admin Console > Users > Roles > Select your Role).
    role_id = "098764"
    privilege_level = "member"
  }
}

# The Strategy your Flow uses to escalate to OneLogin Roles
resource "sym_strategy" "access_onelogin" {
  type           = "onelogin"
  name           = "access-onelogin-strategy"
  integration_id = sym_integration.access_onelogin.id

  # This must be a list of `onelogin_role` sym_target that users can request to be escalated to
  targets = [sym_target.onelogin_admin_role.id, sym_target.onelogin_customer_success_role.id, sym_target.onelogin_power_user_role.id]
}

resource "sym_flow" "access_onelogin" {
  name  = "access-onelogin"
  label = "OneLogin Access"

  implementation = file("${path.module}/impls/onelogin_access_impl.py")
  environment_id = sym_environment.this.id

  vars = {
    "customer_success_target_id" = sym_target.onelogin_customer_success_role.id
  }

  params {
    strategy_id = sym_strategy.access_onelogin.id

    prompt_field {
      name      = "target_id"
      type      = "string"
      required  = true

      # When the Target field selection changes, the on_change_target_id method in this file will be executed.
      on_change = file("./impls/onelogin_on_change.py")
    }

    prompt_field {
      name     = "customer"
      label    = "Customer"
      type     = "string"
      required = true

      # Grab the allowed values for this type-ahead field dynamically
      prefetch = true

      # This field is hidden unless the Customer Success Role is selected, as implemented in onelogin_on_change.py
      visible  = false
    }

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
