namespace :demo do

  desc "Add documents in inbox"

  task :watch_files do
    watcher = CDXSync::FileWatcher.new(sync_directory: 'tmp/cdxsync')
    watcher.ensure_sync_directory
    watcher.watch do |path|
      contents = File.read path
      ## TODO hit cdx server here
    end
  end

end
