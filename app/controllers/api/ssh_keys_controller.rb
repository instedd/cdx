class Api::SshKeysController < ApiController

  def create
    SshKey.create!(params.require(:ssh_key).permit(:device_id, :public_key)
    SshKey.regenerate_authorized_keys! #TODO enqueue
  end

  def destroy
    @ssh_key = SshKey.find(params[:id])
    @ssh_key.destroy
    SshKey.regenerate_authorized_keys!
  end


end
