class NavigationContext
  attr_reader :user

  attr_reader :institution
  attr_reader :site

  def initialize(user = nil, context = nil)
    @user = user
    @context = context
    @include_subsites = !context.end_with?("-!")
    uuid = context.end_with?("-*") || context.end_with?("-!") ? context[0..-3] : context

    @institution = Institution.where(uuid: uuid).take
    @site = nil

    unless @institution
      @site = Site.where(uuid: uuid).take
      @institution = @site.try :institution
    end
  end

  def can_read?
    if @site
      Policy.can?(Policy::Actions::READ_SITE, @site, @user)
    elsif @institution
      Policy.can?(Policy::Actions::READ_INSTITUTION, @institution, @user)
    else
      false
    end
  end

  def entity
    site || institution
  end

  def name
    entity.try :name
  end

  def uuid
    entity.try :uuid
  end

  def exclude_subsites
    !@include_subsites
  end

  def to_hash
    Hash.new.tap do |h|
      if entity
        h[:name] = name
        h[:uuid] = uuid
      end
      h[:full_context] = @context
      h[:sidebar_open] = @user.sidebar_open
      h[:institution] = { name: institution.name, uuid: institution.uuid } if institution
      h[:site] = { name: site.name, uuid: site.uuid } if site
    end
  end
end
