module PagingHelper
  def has_previous_page
    @page > 1
  end

  def has_next_page
    @page < (@total.to_f / @page_size).ceil
  end

  def previous_page_params
    page = @page - 1
    add_page_to_request_uri(page > 0 ? page : 1)
  end

  def next_page_params
    page = @page + 1
    last_page = (@total.to_f / @page_size).ceil
    add_page_to_request_uri(page <= last_page ? page : last_page)
  end

  PAGE_SIZE_OPTIONS = [10, 50, 100].map { |size| ["#{size} #{"row".pluralize(size)} per page", size] }

  private

  def add_page_to_request_uri(page_number)
    uri = Addressable::URI.parse(request.original_url)
    uri.query_values = (uri.query_values || {}).merge({ "page" => page_number })
    uri.to_s
  end
end
