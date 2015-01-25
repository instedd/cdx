module SyncHelpers
  class << self
    def regenerate_authorized_keys!(clients)
      dir = CDXSync::SyncDirectory.new
      ensure_clients_sync_path!(clients, dir)
      CDXSync::AuthorizedKeys.new.write! clients, dir
    end

    def ensure_clients_sync_path!(clients, dir)
      clients.each do |client|
        dir.ensure_client_sync_paths! client.id
      end
    end

    def client_id(device)
      device.secret_key
    end

    def to_client(device, public_key)
      CDXSync::Client.new(client_id(device), public_key)
    end

    def client_settings(client_id)
      dir = CDXSync::SyncDirectory.new
      {
        host: Rails.application.config.ssh_server_host,
        port: Rails.application.config.ssh_server_port,
        user: Rails.application.config.ssh_user,
        inbox_dir: dir.inbox_area,
        outbox_dir: dir.outbox_area
      }
    end
  end
end