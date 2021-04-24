class LaboratorySamplesController < ApplicationController

  def index
    # TODO: filter by Institution
    @samples = LaboratorySample.all

    # paginate samples
    @samples = perform_pagination(@samples)
  end
end
