class ManifestsController < ApplicationController
  add_breadcrumb 'Manifests', :manifests_path

  def index
    @manifests = Manifest.all
  end

  def new
    @manifest = Manifest.new
  end

  def create
    @manifest = Manifest.new(manifest_params)

    respond_to do |format|
      if @manifest.save
        format.html { redirect_to manifests_path, notice: 'Manifest was successfully created.' }
        format.json { render action: 'show', status: :created, manifest: @manifest }
      else
        format.html { render action: 'new' }
        format.json { render json: @manifest.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @manifest = Manifest.find params[:id]
  end

  def update
    @manifest = Manifest.find params[:id]

    respond_to do |format|
      if @manifest.update(manifest_params)
        format.html { redirect_to manifests_path, notice: 'Manifest was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @manifest.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @manifest = Manifest.find params[:id]
    @manifest.destroy

    respond_to do |format|
      format.html { redirect_to manifests_path }
      format.json { head :no_content }
    end
  end

  private

  def manifest_params
    params.require(:manifest).permit(:definition)
  end
end
