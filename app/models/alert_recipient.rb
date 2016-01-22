class AlertRecipient < ActiveRecord::Base
  belongs_to :user
  belongs_to :alert
  belongs_to :role

  enum recipient_type: [:role, :internal_user, :external_user]

  validate :name_validation

  private

  def name_validation
    if recipient_type == "external_user"
      if first_name.length <= 2 
        errors.add(:first_name, "first name too short")
      elsif last_name.length <= 2
        errors.add(:last_name, "last name too short")
      end
    end
  end

end
