namespace :demo do

  desc "Start a watcher for loading all csv files on the sync folder"

  task :watch_files do
    sync_dir = CDXSync::SyncDirectory.new
    sync_dir.init_sync_path!

    watcher = CDXSync::FileWatcher.new(sync_dir)

    watcher.watch do |path|
      CSVEventParser.new.import_from sync_dir
    end
  end

end
