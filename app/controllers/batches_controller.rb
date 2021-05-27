class BatchesController < ApplicationController

  def index
    @batches = Batch.all.order('created_at DESC')

    #paginate batches
    @batches = perform_pagination(@batches)
  end

end
