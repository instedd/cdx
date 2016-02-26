class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
  end

  def settings
    if has_access_to_roles_index?
      @roles_count = check_access(Role, READ_ROLE).within(@navigation_context.entity, @navigation_context.exclude_subsites).count
    end

    if can_delegate_permissions?
      @policies_count = current_user.granted_policies.count
    end

    if has_access_to_test_results_index?
      @alerts_count = current_user.alerts.count
    end
  end

  def verify
    render layout: "messages"
  end

  def join
    render layout: "clean"
  end

  def design
  end
end
