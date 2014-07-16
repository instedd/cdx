class Location < ActiveRecord::Base
  include Resource

  acts_as_nested_set dependent: :destroy

  has_many :laboratories, dependent: :restrict_with_exception
  has_many :devices, :through => :laboratories
  has_many :events, :through => :laboratories

  def self.filter_by_owner(user)
    self
  end

  def filter_by_owner(user)
    self
  end

  def common_root_with(locations)
    locations.inject self do |location, root|
      if root.is_or_is_ancestor_of? location
        location
      elsif root.is_or_is_descendant_of? location
        root
      else
        root_ancestors = root.ancestors
        location.ancestors.sort_by{|l| l.depth}.reverse.find do |ancestor|
          root_ancestors.include? ancestor
        end
      end
    end
  end
end
