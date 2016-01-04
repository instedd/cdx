RevisionFilePath = "#{::Rails.root.to_s}/REVISION"
VersionFilePath = "#{::Rails.root.to_s}/VERSION"

version = if Settings.app_version.presence
    Settings.app_version
  elsif FileTest.exists?(VersionFilePath)
    IO.read(VersionFilePath)
  elsif FileTest.exists?(RevisionFilePath)
    IO.read(RevisionFilePath)
  else
    "latest"
  end

Rails.application.config.version_name = version
