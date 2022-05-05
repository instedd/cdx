# SiteContained applies to entities that belongs both to Institution and to Site.
# It keeps up to date a site_prefix field required to descendant filtering
# Institution is mandatory. Site is optional.
module SiteContained
  extend ActiveSupport::Concern

  included do
    belongs_to :institution, required: true
    belongs_to :site, -> { with_deleted }, required: false

    validate :same_institution_of_site
    before_save :set_site_prefix

    scope :within, -> (institution_or_site, exclude_subsites = false) {
      if institution_or_site.is_a?(Institution) && exclude_subsites
        where(institution: institution_or_site, site: nil)
      elsif institution_or_site.is_a?(Institution) && !exclude_subsites
        where(institution: institution_or_site)
      elsif institution_or_site.is_a?(Site) && exclude_subsites
        where("site_id = ?", institution_or_site.id)
      else
        where("site_prefix LIKE concat(?, '%')", institution_or_site.prefix)
      end
    }

    def set_site_prefix
      self.site_prefix = site.try(:prefix)
    end

    def same_institution_of_site
      if self.site && self.site.institution != self.institution
        errors.add(:site, "must belong to the institution")
      end
    end
  end
end
