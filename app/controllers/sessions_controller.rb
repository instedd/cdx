class SessionsController < Devise::SessionsController
  skip_before_action :check_no_institution!, only: :destroy
  skip_before_action :ensure_context
end
