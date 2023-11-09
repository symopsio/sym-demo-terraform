import requests

from sym.sdk.annotations import prefetch, reducer
from sym.sdk.integrations import slack
from sym.sdk.field_option import FieldOption


# Reducers fill in the blanks that your workflow needs in order to run.
# For more information, please see https://docs.symops.com/docs/reducers
@reducer
def get_approvers(event):
    """Route Sym requests to a specified channel."""

    # Make sure that this channel has been created in your workspace!
    return slack.channel("#sym-requests", allow_self=True)


@prefetch(field_name="customer")
def get_customer_list(event):
    response = requests.get(url="https://api.symops.com/internal/customers")
    customers = response.json()["results"]

    return [
        FieldOption(value=customer["id"], label=customer["name"])
        for customer in customers
    ]
