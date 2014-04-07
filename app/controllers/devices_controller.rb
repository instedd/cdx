class DevicesController < ApplicationController
  before_action :set_device, only: [:show, :edit, :update, :destroy, :regenerate_key]
  before_action :load_laboratories, only: [:new, :edit]

  def index
    @devices = Device.all
  end

  def show
  end

  def new
    @device = Device.new
  end

  def edit
  end

  def regenerate_key
    @device.set_key
    respond_to do |format|
      if @device.save
        format.html { redirect_to @device, notice: 'Key updated' }
        format.json { render action: 'show', location: @device }
      else
        format.html { render action: 'edit' }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @device = Device.new(device_params)

    respond_to do |format|
      if @device.save
        format.html { redirect_to @device, notice: 'Device was successfully created.' }
        format.json { render action: 'show', status: :created, location: @device }
      else
        format.html { render action: 'new' }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @device.update(device_params)
        format.html { redirect_to @device, notice: 'Device was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @device.destroy
    respond_to do |format|
      format.html { redirect_to devices_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_device
      @device = Device.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def device_params
      params.require(:device).permit(:name, :laboratory_id, :index_name)
    end

    def load_laboratories
      @laboratories = current_user.laboratories
    end
end
