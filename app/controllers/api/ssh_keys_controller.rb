class Api::SshKeysController < ApiController

  before_action :set_ssh_key, only: [:destroy]

  def create
    SshKey.create!(ssh_key_params)
    SshKey.regenerate_authorized_keys! #TODO enqueue
  end

  def destroy
    @ssh_key.destroy
    SshKey.regenerate_authorized_keys!
  end


  private 

  def set_ssh_key
    @ssh_key = SshKey.find(params[:id])
  end

  def ssh_key_params
    params.require(:ssh_key).permit(:device_id, :public_key)
  end

end
