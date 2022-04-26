class TransferPackage < ApplicationRecord
  belongs_to :sender_institution, class_name: "Institution"
  belongs_to :receiver_institution, class_name: "Institution"
  has_many :sample_transfers

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
      if includes_qc_info && (qc_info = create_qc_info(sample))
        sample.qc_info = qc_info
      end

      sample.old_batch_number = sample.batch.batch_number
    end

    sample.update!(batch: nil, site: nil, institution: nil)

    transfer
  end

  private

  def create_qc_info(sample)
    sample_qc = sample.batch.qc_sample
    return unless sample_qc

    qc_info = QcInfo.find_or_duplicate_from(sample_qc)
    qc_info.samples << sample
    qc_info.save!
    qc_info
  end
end
