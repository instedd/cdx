class LaboratorySamplesController < ApplicationController

  def index
    @samples = [
      LaboratorySample.new,
      LaboratorySample.new
    ]
  end
end
