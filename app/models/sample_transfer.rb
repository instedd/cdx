class SampleTransfer < ActiveRecord::Base
  belongs_to :sample
  belongs_to :sender_institution, class_name: "Institution"
  belongs_to :receiver_institution, class_name: "Institution"

  validates_presence_of :sample
  validates_presence_of :sender_institution
  validates_presence_of :receiver_institution

  after_initialize do
    self.sender_institution ||= sample.try &:institution
  end

  scope :within, ->(institution) {
          where("sender_institution_id = ? OR receiver_institution_id = ?", institution.id, institution.id)
        }

  scope :ordered_by_creation, -> {
          order(created_at: :desc)
        }

  def confirm
    if confirmed?
      self.errors.add(:confirmed_at, "Already confirmed.")
      false
    else
      self.confirmed_at = Time.now
      true
    end
  end

  def confirm!
    confirm
    save!
  end

  def confirm_and_apply!
    sample.update!(institution: receiver_institution)
    confirm!
  end

  def confirmed?
    !!confirmed_at
  end
end
