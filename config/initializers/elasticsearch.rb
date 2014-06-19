module Elasticsearch
  def self.index_prefix
    "cdp_institution_#{Rails.env}"
  end
end
