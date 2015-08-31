module TestResultsHelper
  def format_datetime(value)
    return nil unless value
    Time.parse(value).strftime("%Y-%m-%d %H:%M")
  end

  def order_by_column(title, field)
    desc_field = "-#{field}"
    link_order_by = @order_by == field ? desc_field : field

    link = link_to title, params.merge(order_by: link_order_by)
    if @order_by == field
      link.safe_concat(" \u{2191}")
    elsif @order_by == desc_field
      link.safe_concat(" \u{2193}")
    else
      link
    end
  end
end
