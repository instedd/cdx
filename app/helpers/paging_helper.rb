module PagingHelper
  def has_previous_page
    @page > 1
  end

  def has_next_page
    @page < (@total.to_f / @page_size).ceil
  end

  def previous_page_params
    params.merge("page" => [@page - 1, 1].max)
  end

  def next_page_params
    params.merge("page" => [@page + 1, (@total.to_f / @page_size).ceil].min)
  end

  PAGE_SIZE_OPTIONS = Hash[[1, 5, 15, 50].map { |size| ["#{size} #{"row".pluralize(size)} per page", size] }]

  def options_for_page_sizes
    options_for_select(PAGE_SIZE_OPTIONS, @page_size)
  end
end
