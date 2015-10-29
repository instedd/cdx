require 'cdx_sync'
namespace :manifests do
  desc "Creates device models from seed manifests"
  task :load => :environment do |task, args|
    activations = {
      "Cepheid Gene Xpert" => false,
      "Epicenter M.G.I.T. Spanish" => true,
      "Fio" => false,
      "Genoscan" => true,
      "Qiagen Esequant Lr3" => false,
    }

    Dir.glob(File.join(Rails.root, 'db', 'seeds', 'manifests', '*.json')) do |path|
      name = File.basename(path, '_manifest.json').titleize
      activation = activations[name]
      if activation.nil?
        raise "Missing activation definition for #{path}, check #{__FILE__}, line 5"
      end

      device_model = DeviceModel.find_or_create_by! name: name
      device_model.update manifest_attributes: {definition: IO.read(path)}, supports_activation: activation
      device_model.tap(&:set_published_at).save!
    end
  end
end
