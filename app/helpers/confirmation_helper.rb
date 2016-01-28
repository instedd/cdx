module ConfirmationHelper
  def confirm_deletion_button target, entity_type=nil, relations=nil
    entity_type ||= target.model_name.singular
    relations ||= target.destroy_restrict_associations_with_elements.map{|assoc| assoc.plural_name.humanize(capitalize: false)}.to_sentence.presence || 'entities'
    link_to_if target.can_destroy?, "Delete", target, method: :delete, data: { confirm: "You're about to permanently delete this #{entity_type}. This action CANNOT be undone. Are you sure you want to proceed?" }, class: 'btn-secondary pull-right', title: "Delete #{entity_type.capitalize}" do
      content_tag :span, "Cannot delete", title: "This #{entity_type} has associated #{relations}.", class: 'btn-link not-allowed pull-right'
    end
  end
end
