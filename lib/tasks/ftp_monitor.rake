namespace :ftp do
  desc "Start FTP monitor to download remote files"
  task start: :environment do
    FtpMonitor.new(300).run!
  end

  desc "Delete the failed file messages as a way to reprocess those files in the next monitoring iteration"
  task reset_failed: :environment do
    FileMessage.where(status: 'failed').delete_all
  end
end
