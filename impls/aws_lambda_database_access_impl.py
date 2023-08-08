from sym.sdk.annotations import reducer, prefetch, hook
from sym.sdk.integrations import slack, aws_lambda
from sym.sdk.field_option import FieldOption
from sym.sdk.templates import ApprovalTemplateStep


# Reducers fill in the blanks that your workflow needs in order to run.
# For more information, please see https://docs.symops.com/docs/reducers
@reducer
def get_approvers(event):
    return slack.fallback(
        # After 15 seconds, the initial request will expire and go to the backup channel.
        slack.channel("#sym-requests", allow_self=True, timeout=15),
        # After another 60 seconds, the request will expire forever.
        slack.channel("#sym-backup-approvers", allow_self=True, timeout=30),
        continue_on_timeout=True,
    )


# Prefetch reducers are called before a request form is shown to a user, and are used to
# dynamically populate typeahead dropdowns in the form.
# This prefetch reducer will fill in the options for the "database_role" field.
@prefetch(field_name="database_role")
def get_database_role(event):
    # Call out to an AWS Lambda to get all current database roles.
    options = aws_lambda.invoke("arn:aws:lambda:us-east-1:1234567890:function:get-database-roles")

    # Return a list of options for the Slack dropdown based on the roles retrieved.
    return [FieldOption(value=item["role"], label=item["role"]) for item in options]


# Hooks are used to add additional logic to your workflow when certain events happen.
# after_request happens after the access request has been sent to the approvers.
@hook
def after_request(event):
    # We can use Sym's data to know what access this user has requested in the past.
    if event.user.get_event_count(ApprovalTemplateStep.REQUEST) == 1:
        # If this is the first request this user has ever made using this Flow, send an additional
        # alert in Slack notifying the approvers, since it may be anomalous.
        slack.send_message(slack.channel("#sym-requests"), ":warning: Notice: This is the first time this user has requested access to this resource.")
