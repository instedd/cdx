class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :timeoutable
  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :trackable,
         :validatable, :confirmable, :timeoutable,
         :lockable, :password_expirable, :password_archivable

  devise :omniauthable, :registerable unless Settings.single_tenant

  validates_format_of :email, without: /,/

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
  has_many :alert_recipients
  has_many :recipient_notification_history

  include Resource

  after_create :update_computed_policies

  scope :within, -> (institution_or_site, exclude_subsites = false) {
    if institution_or_site.is_a?(Institution) && exclude_subsites
      joins(:roles).where("roles.institution_id = ? AND roles.site_id IS NULL", institution_or_site.id)
    elsif institution_or_site.is_a?(Institution)
      joins(:roles).where("roles.institution_id = ?", institution_or_site.id)
    elsif institution_or_site.is_a?(Site) && exclude_subsites
      joins(:roles).where("roles.site_id = ?", institution_or_site.id)
    else
      ids = Site.within(institution_or_site).pluck(:id)
      joins(:roles).where("roles.site_id IN (?)", ids)
    end.uniq
  }

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

  def active_for_authentication?
    super && self.is_active?
  end

  def inactive_message
    self.is_active? ? super : I18n.t('devise.failure.suspended')
  end
end
