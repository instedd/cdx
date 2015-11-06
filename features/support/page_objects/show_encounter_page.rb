class ShowEncounterPage < SitePrism::Page
  include CdxPageHelper

  set_url "/encounters/{id}"

  def id
    url_matches['id'].to_i
  end
end
