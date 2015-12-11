require 'cdx_sync'
namespace :manifests do
  desc "Creates device models from seed manifests and creates their associated institutions with default users"
  task :load => :environment do |task, args|
    default_password = ENV['PASSWORD']
    raise "Please specify `password` environment variable to be used as the default password for all admins" if default_password.blank?

    data = {
      'cepheid_gene_xpert' => {
        activation: false,
        institution: 'Cepheid',
        owner: 'cepheid_admin@instedd.org'
      },
      'epicenter_m.g.i.t._spanish' => {
        activation: true,
        institution: 'BD',
        owner: 'bd_admin@instedd.org'
      },
      'fio' => {
        activation: false,
        institution: "Fio Corporation",
        owner: "fio_admin@instedd.org"
      },
      'genoscan' => {
        activation: true,
        institution: 'Hain Lifescience',
        owner: 'hain_admin@instedd.org'
      },
      'qiagen_esequant_lr3' => {
        activation: false,
        institution: 'Qiagen',
        owner: "qiagen_admin@instedd.org"
      },
      'bdmicro_imager' => {
        activation: false,
        institution: 'BD',
        owner: 'bd_admin@instedd.org'
      }
    }

    ActiveRecord::Base.transaction do
      data.each do |name, props|
        manifest = File.read(File.join(Rails.root, 'db', 'seeds', 'manifests', "#{name}_manifest.json"))
        activation = props[:activation]

        device_model = DeviceModel.find_or_create_by!(name: name.titleize) do |device_model|
          device_model.institution = Institution.find_or_create_by!(name: props[:institution]) do |institution|
            owner = User.create_with(password: default_password).find_or_create_by!(email: props[:owner]) do |u|
              u.skip_confirmation!
            end
            institution.user = owner
            institution.kind = 'manufacturer'
          end
        end

        device_model.update manifest_attributes: {definition: manifest}, supports_activation: activation
        device_model.tap(&:set_published_at).save!
      end
    end

  end
end
