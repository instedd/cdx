require 'cdx_sync'

CDXSync.instance_eval do

  def default_sync_dir_path
    Rails.application.config.sync_dir_path
  end

  def default_authorized_keys_path
    Rails.application.config.authorized_keys_path
  end

  def rrsync_location
    '/usr/local/bin/rrsync'
  end
end

CDXSync::Client.class_eval do
  def authorized_keys_entry(sync_dir)
    #FIXME remove this.
    #We need to use rrsync, but the problem is that sync_dir has paths local to this server,
    #but not to the sshd-server. We need to add a translation for both paths, or use same path
    #in both containers, or make the sync_dir aware of that mismatch, or have two sync_dirs - one local and one remote
    "no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding #{public_key}"
  end
end