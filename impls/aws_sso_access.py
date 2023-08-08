from sym.sdk.annotations import reducer, hook
from sym.sdk.integrations import slack, aws_sso
from sym.sdk.templates import ApprovalTemplate


# Reducers fill in the blanks that your workflow needs in order to run.
# For more information, please see https://docs.symops.com/docs/reducers
@reducer
def get_approvers(event):
    """Route Sym requests to a specified channel."""

    # Make sure that this channel has been created in your workspace!
    return slack.channel("#sym-requests", allow_self=False)


# Hooks are used to add additional logic to your workflow when certain events happen.
# on_approve happens when the "Approve" button is clicked on a request.
@hook
def on_approve(event):
    # Reach out to AWS SSO and check if the approver is in the "interns" group in AWS SSO.
    if aws_sso.is_user_in_group(event.user, group_name="interns"):
        # The user is an intern, so we want to ignore the approval.
        # The access request will remain open.
        return ApprovalTemplate.ignore(message="Interns cannot approve access requests.")
