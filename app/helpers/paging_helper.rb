module PagingHelper
  def has_previous_page
    @page > 1
  end

  def has_next_page
    @page < (@total.to_f / @page_size).ceil
  end

  def previous_page_params
    new_params = params.merge("page" => [@page - 1, 1].max)
    new_params.permit!
  end

  def next_page_params
    new_params =  params.merge("page" => [@page + 1, (@total.to_f / @page_size).ceil].min)
    new_params.permit!
  end

  PAGE_SIZE_OPTIONS = [10, 50, 100].map { |size| ["#{size} #{"row".pluralize(size)} per page", size] }
end
