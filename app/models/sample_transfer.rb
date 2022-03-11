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

  scope :with_receiver, ->(institution) {
          where(receiver_institution_id: institution.id)
        }

  scope :ordered_by_creation, -> {
          order(created_at: :desc)
        }

  def confirm
    if confirmed?
      false
    else
      self.confirmed_at = Time.now
      true
    end
  end

  def confirm!
    if confirm
      save!
    else
      raise ActiveRecord::RecordNotSaved.new("Sample transfer has already been confirmed.")
    end
  end

  def confirm_and_apply
    if confirm
      save!
      sample.update!(institution: receiver_institution)
      true
    else
      false
    end
  end

  def confirm_and_apply!
    confirm!
    sample.update!(institution: receiver_institution)

    nil
  end

  def confirmed?
    !!confirmed_at
  end
end
