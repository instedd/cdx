Dir.glob(File.join(Rails.root, 'db', 'seeds', 'manifests', '*.json')) do |path|
  Manifest.create! definition: IO.read(path)
end
