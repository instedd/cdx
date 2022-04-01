class TransferPackage < ActiveRecord::Base
  belongs_to :receiver_institution, class_name: "Institution"
  has_many :sample_transfers

  after_initialize do
    self.uuid ||= SecureRandom.uuid
  end

  def self.sending_to(institution, attributes = nil)
    create!(attributes) do |package|
      package.receiver_institution = institution
    end
  end

  def add!(sample)
    transfer = sample_transfers.create!(
      sample: sample,
      receiver_institution: receiver_institution,
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
