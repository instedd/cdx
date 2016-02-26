namespace :ftp do

  desc "Start FTP monitor to download remote files"
  task :start => :environment do
    FtpMonitor.new(300).run!
  end
end
