module ConfirmationHelper
  def confirm_deletion_button target, entity_type
    link_to "Delete", target, method: :delete, data: { confirm: "You're about to permanently delete this #{entity_type}. This action CANNOT be undone. Are you sure you want to proceed?" }, class: 'btn-secondary pull-right', title: "Delete #{entity_type.capitalize}"
  end
end
