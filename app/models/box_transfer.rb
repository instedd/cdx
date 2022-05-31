class BoxTransfer < ActiveRecord::Base
  belongs_to :box
  belongs_to :transfer_package

  # TODO: remove these after upgrading to Rails 5.0 (belongs_to associations are required by default):
  validates_presence_of :box
end
