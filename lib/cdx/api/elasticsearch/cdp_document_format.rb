class CDPDocumentFormat

    def default_sort
      "created_at"
    end

    def indexed_field_name(cdp_field_name)
      cdp_field_name
    end

    # receives an event in the format used in ES and
    # translates it into a CDP compliant response
    def translate_event(event)
      event
    end

    private

    def cdp_field_name(indexed_field_name)
      indexed_field_name
    end

end