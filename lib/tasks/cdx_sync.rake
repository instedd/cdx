namespace :demo do

  desc "Add documents in inbox"

  task :watch_files do
    sync_dir = CDXSync::SyncDirectory.new
    sync_dir.init_sync_path!

    watcher = CDXSync::FileWatcher.new(sync_dir)

    watcher.watch do |path|
      contents = File.read path
      # process file here
      File.delete path
    end
  end

end
