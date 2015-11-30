class Role < ActiveRecord::Base
  belongs_to :institution
  belongs_to :site
  belongs_to :policy
  has_and_belongs_to_many :users

  attr_accessor :definition

  validates_presence_of :name
  validates_presence_of :institution
  validates_presence_of :policy
  validate :validate_site

  private

  def validate_site
    if site && site.institution != institution
      errors.add(:site, "must belong to the selected institution")
    end
  end
end
