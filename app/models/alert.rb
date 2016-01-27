class Alert < ActiveRecord::Base
  belongs_to :user
  belongs_to :site

  has_many :alert_histories
  has_many :alert_recipients
  has_many  :recipient_notification_history

  has_and_belongs_to_many :sites
  has_and_belongs_to_many :devices

  after_update :recreate_alert_percolator
  after_destroy :delete_percolator

  accepts_nested_attributes_for :alert_recipients, reject_if: :all_blank, allow_destroy: true

  serialize :query, JSON

  validates_presence_of :user
  #TODO  validates :error_code, format: { with: /^\d+/, message: "must start with a letter" }

  #html5 form validations also done
  validates_presence_of :name
  #maybe a user just wants sms_message ,not an email message: validates_presence_of :message
  #  validates_presence_of :description
  #  validates_presence_of :site

  enum category_type: [:anomalies, :device_errors, :quality_assurance, :test_results, :utilization_efficiency]
  enum aggregation_type: [:record, :aggregated]
  enum aggregation_frequency: [:hour, :day]
  enum channel_type: [:email, :sms, :email_and_sms]

  enum anomalie_type: [:missing_sample_id, :missing_start_time]

  #for the alert _form, could not get the cdx_select element working when referencing a child table
  attr_accessor :roles
  attr_accessor :sites_info
  attr_accessor :devices_info
  attr_accessor :users_info


  def create_percolator
    es_query =  TestResult.query(self.query, self.user).elasticsearch_query
    return unless es_query
    Cdx::Api.client.index index: Cdx::Api.index_name_pattern,
    type: '.percolator',
    id: 'alert_'+self.id.to_s,
    body: { query: es_query, type: 'test' }

  end

  def recreate_alert_percolator
    #when you disable an alert ,it will be deleted from elasticsearch
    if self.enabled==true
      create_percolator
    end
  end

  def delete_percolator
    Cdx::Api.client.delete index: Cdx::Api.index_name_pattern,
    type: '.percolator',
    id: 'alert_'+id.to_s,
    ignore: 404
  end

end
