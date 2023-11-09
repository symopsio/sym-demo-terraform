def on_change_target_id(username, prompt_form):
    customer_success_group = prompt_form.flow_vars["customer_success_target_id"]

    target_field = prompt_form.fields.get("target_id")
    customer_field = prompt_form.fields.get("customer")

    # If the selected OneLogin group is the Customer Success group, then display the "customer" prompt field.
    if target_field.value == customer_success_group:
        customer_field.visible = True
    else:
        customer_field.visible = False

    return prompt_form
