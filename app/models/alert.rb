class Alert < ActiveRecord::Base
  belongs_to :user
 
  has_many :alert_histories
  has_many :alert_recipients
   
  accepts_nested_attributes_for :alert_recipients, reject_if: :all_blank, allow_destroy: true

  serialize :query, JSON

  validates_presence_of :user
#TODO  validates :error_code, format: { with: /^\d+/, message: "must start with a letter" }
  validates_presence_of :name
  validates_presence_of :description
  
  enum category_type: [ :anomalies, :device_errors, :quality_assurance, :test_results, :utilization_efficiency, :workflow_delays]  
  enum aggregation_type: [ :per_record, :aggregated]
  enum channel_type: [ :web, :sms, :sms_and_web]

  
#TODO  after_destroy :delete_percolator
#TODO  after_update :recreate_alert_percolators

  def create_percolator
    #binding.pry
    es_query =  TestResult.query(self.query, self.user).elasticsearch_query
    return unless es_query
    
    Cdx::Api.client.index index: Cdx::Api.index_name_pattern,
                          type: '.percolator',
                          id: 'alert_'+self.id.to_s,
                          body: { query: es_query, type: 'test' }                                                    
   end

   def recreate_alert_percolators
     alerts.each &:create_percolator
   end
    
   def delete_percolator
     Cdx::Api.client.delete index: Cdx::Api.index_name_pattern,
                            type: '.percolator',
                            id: 'alert_'+self.id,
                            ignore: 404
   end


end
