class DeviceModelsController < ApplicationController
  expose(:device_models) { DeviceModel.includes(:manifest) }
  expose(:device_model, attributes: :device_model_params)

  def create
    respond_to do |format|
      if device_model.save
        format.html { redirect_to device_models_path, notice: 'Device Model was successfully created.' }
        format.json { render action: 'show', status: :created, device_model: device_model }
      else
        format.html { render action: 'new' }
        format.json { render json: device_model.errors, status: :unprocessable_entity }
      end
    end
  end

  def new
    device_model.manifest = Manifest.new
  end

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if device_model.update(device_model_params)
        format.html { redirect_to device_models_path, notice: 'Device Model was successfully updated.' }
        format.json { render action: 'show', status: :created, device_model: device_model }
      else
        format.html { render action: 'new' }
        format.json { render json: device_model.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    device_model.destroy

    respond_to do |format|
      format.html { redirect_to device_models_path }
      format.json { head :no_content }
    end
  end

  private

  def device_model_params
    params.require(:device_model).permit(:name, manifest_attributes: [:definition])
  end
end
