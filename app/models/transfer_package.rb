class TransferPackage < ApplicationRecord
  belongs_to :sender_institution, class_name: "Institution"
  belongs_to :receiver_institution, class_name: "Institution"
  has_many :box_transfers
  has_many :boxes, through: :box_transfers
  has_many :samples, through: :boxes

  accepts_nested_attributes_for :box_transfers,
    allow_destroy: true,
    reject_if: :all_blank

  validates_associated :box_transfers
  validates_size_of :box_transfers, minimum: 1, message: "must not be empty"

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
    box_transfers.each do |box_transfer|
      box = box_transfer.box
      box.attach_qc_info if includes_qc_info
      box.detach_from_context unless confirmed?
      box.save!
    end
  end

  def self.sending(sender, receiver, attributes = nil)
    create!(attributes) do |package|
      package.sender_institution = sender
      package.receiver_institution = receiver
    end
  end

  def add(box)
    box_transfers.build(box: box)
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
