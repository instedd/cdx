class Api::PlaygroundController <ApiController
  def index
    @devices = check_access(Device, READ_DEVICE)
  end
end
