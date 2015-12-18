class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :timeoutable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :confirmable, :omniauthable, :timeoutable,
         :lockable, :password_expirable, :password_archivable

  has_many :identities, dependent: :destroy
  has_many :institutions
  has_many :sites, through: :institutions
  has_many :devices, through: :institutions
  has_many :filters
  has_many :subscribers
  has_many :policies
  has_many :granted_policies, class_name: "Policy", foreign_key: "granter_id"
  has_many :computed_policies
  has_and_belongs_to_many :roles
  has_many :alerts
  has_many :alert_histories
#friday   has_many :alert_recipients
  has_many  :recipient_notification_history

  after_create :update_computed_policies

  def timeout_in
    Settings.web_session_timeout.try{ |timeout| timeout.to_i.seconds }
  end

  def create(model)
    if model.respond_to?(:user=)
      model.user = self
    end
    model.save ? model : nil
  end

  def implicit_policies
    self.institutions.pluck(:id, :kind).map do |institution_id, kind|
      Policy.owner(self, institution_id, kind)
    end + [(Policy.implicit(self) unless Settings.single_tenant)].compact
  end

  def invited_pending?
    invitation_created_at && !invitation_accepted_at
  end

  def update_computed_policies
    ComputedPolicy.update_user(self)
  end

  def full_name
    [first_name, last_name].compact.join(' ').presence || email
  end

  def grant_superadmin_policy
    grant_predefined_policy("superadmin")
  end

  def grant_predefined_policy(name, args={})
    predefined = Policy.predefined_policy(name, self, args)
    predefined.granter = nil
    predefined.user = self
    predefined.save!
  end

  DEFAULT_OAUTH2_APPLICATION_NAME = "Default OAuth2 Application"

  def default_oauth2_application
    app = Doorkeeper::Application.where(owner_id: id, owner_type: self.class.name, name: DEFAULT_OAUTH2_APPLICATION_NAME).first
    unless app
      app = Doorkeeper::Application.new
      app.owner = self
      app.name = DEFAULT_OAUTH2_APPLICATION_NAME
      app.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
      app.save!
    end
    app
  end

  def create_api_token
    token = default_oauth2_application.access_tokens.new
    token.resource_owner_id = self.id
    token.save!
    token
  end
end
