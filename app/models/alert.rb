class Alert < ActiveRecord::Base
  belongs_to :user
  belongs_to :site

  has_many :alert_histories
  has_many :alert_recipients
  has_many :recipient_notification_history
  has_many :alert_condition_results

  has_and_belongs_to_many :sites
  has_and_belongs_to_many :devices
  has_and_belongs_to_many :conditions

  acts_as_paranoid

  after_update :recreate_alert_percolator
  after_destroy :delete_percolator

  accepts_nested_attributes_for :alert_recipients, reject_if: :all_blank, allow_destroy: true

  serialize :query, JSON

  validates_presence_of :user
  validates_presence_of :name    #html5 form validations also done
  validate :category_validation

  enum category_type: [:anomalies, :device_errors, :quality_assurance, :test_results, :utilization_efficiency]
  enum aggregation_type: [:record, :aggregated]
  enum aggregation_frequency: [:hour, :day]
  enum channel_type: [:email, :sms, :email_and_sms]
  
  #Note: elasticsearch filter issue  with start_time, for some reason, {"test.start_time"=>"null"}, does not work.
  #enum anomalie_type: [:missing_sample_id, :missing_start_time]
  enum anomalie_type: [:missing_sample_id]

  enum utilization_efficiency_type: [:sample]

  #for the alert _form, could not get the cdx_select element working when referencing a child table
  attr_accessor :roles
  attr_accessor :sites_info
  attr_accessor :devices_info
  attr_accessor :users_info
  attr_accessor :conditions_info
  attr_accessor :condition_results_info


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

  private

  def  is_integer?(str_val)
    str_val.to_i.to_s == str_val
  end


  def category_validation
    if category_type == "device_errors"
      error=false;
      if error_code.include? '-'
        minmax=error_code.split('-')
        error = true if !is_integer?(minmax[0])
        error = true if !is_integer?(minmax[1]) 
      else
        error = true if !is_integer?(error_code)
      end

      if error
        errors.add(:error_code, "errorcode must be an integer")
      end

    elsif category_type == "utilization_efficiency"
      if (utilization_efficiency_number==0)
        errors.add(:utilization_efficiency_number, "Timespan cannot be zero")
      end
      if ( (sample_id == nil) || (sample_id.length==0)  )
        errors.add(:sample_id, "Sample ID cannot be empty")
      end
    end
  end

end
