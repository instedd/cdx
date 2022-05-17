class TransferPackage < ApplicationRecord
  belongs_to :sender_institution, class_name: "Institution"
  belongs_to :receiver_institution, class_name: "Institution"
  has_many :sample_transfers

  accepts_nested_attributes_for :sample_transfers,
    allow_destroy: true,
    reject_if: :all_blank

  validates_associated :sample_transfers

  # TODO: remove these after upgrading to Rails 5.0 (belongs_to associations are required by default):
  validates_presence_of :sender_institution
  validates_presence_of :receiver_institution

  after_initialize do
    self.uuid ||= SecureRandom.uuid
  end

  scope :within, ->(institution) {
          if Rails::VERSION::MAJOR >= 5
            where(sender_institution_id: institution.id).or(with_receiver(institution))
          else
            where(arel_table[:sender_institution_id].eq(institution.id).or(arel_table[:receiver_institution_id].eq(institution.id)))
          end
        }

  scope :with_receiver, ->(institution) {
          where(receiver_institution_id: institution.id)
        }

  before_create do
    sample_transfers.each do |sample_transfer|
      sample = sample_transfer.sample
      sample.detach_from_context unless confirmed?
      sample.attach_qc_info if includes_qc_info
      sample.save!
    end
  end

  def self.sending(sender, receiver, attributes = nil)
    create!(attributes) do |package|
      package.sender_institution = sender
      package.receiver_institution = receiver
    end
  end

  def add!(sample)
    transfer = sample_transfers.create!(
      sample: sample,
    )

    if sample.batch
      if includes_qc_info
        sample.attach_qc_info
      end

      sample.old_batch_number = sample.batch.batch_number
    end

    sample.update!(batch: nil, site: nil, institution: nil)

    transfer
  end

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
      raise ActiveRecord::RecordNotSaved.new("Transfer package has already been confirmed.")
    end
  end

  def confirmed?
    !!confirmed_at
  end
end
