class ProspectsPage < SitePrism::Page
  set_url '/prospects'

  section :results, '#prospects' do
    elements :rows, 'tr.prospect'
  end
end
