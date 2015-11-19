module UsersHelper
  def last_activity(user)
    if user.invited_pending?
      sent_at = user.invitation_created_at
      return "Invitation sent #{sent_at.to_formatted_s(:long)}"
    end

    return 'Never logged in' unless user.last_sign_in_at
    return user.last_sign_in_at.to_formatted_s(:long)
  end
end
