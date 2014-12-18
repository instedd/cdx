class Api::SshKeysController < ApiController

  def create
    DeviceSshKey.create!(params.require(:ssh_key).permit(:device_id, :public_key)
    DeviceSshKey.regenerate_authorized_keys! #TODO enqueue
  end

  def destroy
    @ssh_key = DeviceSshKey.find(params[:id])
    @ssh_key.destroy
    DeviceSshKey.regenerate_authorized_keys!
  end


end
