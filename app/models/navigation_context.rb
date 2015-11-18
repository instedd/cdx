class NavigationContext
  attr_reader :user

  attr_reader :institution
  attr_reader :site

  def initialize(user, uuid)
    @user = user

    @institution = Institution.where(uuid: uuid).first
    @site = nil

    if @institution
      Policy.authorize Policy::Actions::READ_INSTITUTION, @institution, @user
    else
      @site = Site.where(uuid: uuid).first
      if @site
        Policy.authorize Policy::Actions::READ_SITE, @site, @user
        @institution = @site.institution
      end
    end
  end

  def entity
    site || institution
  end

  def name
    entity.name
  end

  def uuid
    entity.uuid
  end

  def to_hash
    entity ? {name: name, uuid: uuid} : {}
  end
end
