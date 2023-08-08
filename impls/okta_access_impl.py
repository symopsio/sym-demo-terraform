from sym.sdk.annotations import reducer, hook
from sym.sdk.integrations import slack, pagerduty
from sym.sdk.templates import ApprovalTemplate


# Reducers fill in the blanks that your workflow needs in order to run.
# For more information, please see https://docs.symops.com/docs/reducers
@reducer
def get_approvers(event):
    """Route Sym requests to a specified channel."""

    # Make sure that this channel has been created in your workspace!
    return slack.channel("#sym-requests", allow_self=True)


# Hooks are used to add additional logic to your workflow when certain events happen.
# on_request happens when the request form is submitted.
@hook
def on_request(event):
    # Automatically approve access requests for on-call employees to the Okta Admin group.
    target_group = event.payload.fields.get("target").slug
    if target_group == "okta-admin-group" and pagerduty.is_on_call(event.user):
        original_reason = event.payload.fields.get("reason")

        # Update the request message to show that the request was auto-approved.
        return ApprovalTemplate.approve(reason=f":warning: On call, auto-approved: {original_reason}")
