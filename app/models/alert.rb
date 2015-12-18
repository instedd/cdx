class Alert < ActiveRecord::Base
  belongs_to :user
  belongs_to :site
 
  has_many :alert_histories
  has_many :alert_recipients
  has_many  :recipient_notification_history
  
   
  accepts_nested_attributes_for :alert_recipients, reject_if: :all_blank, allow_destroy: true

  serialize :query, JSON

  validates_presence_of :user
#TODO  validates :error_code, format: { with: /^\d+/, message: "must start with a letter" }
  validates_presence_of :name
  validates_presence_of :description
#  validates_presence_of :site
 
 #in the view,could not get this working':alert_recipient.id' working::  cdx_select form: f, name: alert_recipient, class: 'input-x-large' do |select|
 #so fix was to use a new varible
#  attr_accessor :roles
  
  enum category_type: [ :anomalies, :device_errors, :quality_assurance, :test_results, :utilization_efficiency, :workflow_delays]  
  enum aggregation_type: [ :per_record, :aggregated]
  enum aggregation_frequency: [ :per_hour, :per_day, :per_month]
  enum channel_type: [ :web, :sms, :sms_and_web]
  
  #for the alert _form, could not get the cdx_select element working when referencing a child table 
  attr_accessor :roles
  
 after_update :recreate_alert_percolator
  
 after_destroy :delete_percolator

  def create_percolator
    es_query =  TestResult.query(self.query, self.user).elasticsearch_query
    return unless es_query
    
    Cdx::Api.client.index index: Cdx::Api.index_name_pattern,
                          type: '.percolator',
                          id: 'alert_'+self.id.to_s,
                          body: { query: es_query, type: 'test' }                                                                         
   end

=begin
   def recreate_alert_percolators
     alerts = Alert.find_by_user_id(current_user.id)
     alerts.each &:create_percolator
   end
=end
   
   def recreate_alert_percolator
     create_percolator
    end
    
   def delete_percolator
     Cdx::Api.client.delete index: Cdx::Api.index_name_pattern,
                            type: '.percolator',
                            id: 'alert_'+id.to_s,
                            ignore: 404
   end


end
