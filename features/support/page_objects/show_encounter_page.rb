class ShowEncounterPage < CdxPageBase
  set_url "/encounters/{id}"

  def id
    url_matches['id'].to_i
  end

  def encounter
    Encounter.find(self.id)
  end
end
