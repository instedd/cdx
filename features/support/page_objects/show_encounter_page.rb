class ShowEncounterPage < CdxPageBase
  set_url "/encounters/{id}"

  def id
    url_matches['id'].to_i
  end
end
