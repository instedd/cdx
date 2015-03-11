# Ensure Event class is loaded first from app/models before reopening it to ensure its super class is properly set
Event; class Event
  def self.create_and_index indexed_fields, params={}
    event = self.make params
    EventIndexer.new(indexed_fields, event).index
    event
  end
end
