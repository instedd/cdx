class TestsRun < SitePrism::Section
  class PieChart < SitePrism::Section
    element :total, 'svg .main.total:first-child'
  end

  section :pie_chart, PieChart, '[data-react-class="PieChart"]'
end
