namespace :institutions do
  desc "Creates demo institutions and health organisations"
  task :load => :environment do
    default_password = ENV['PASSWORD']
    raise "Please specify `password` environment variable to be used as the default password for all admins" if default_password.blank?

    data = {
      "Demo Institution" => {
        kind: "institution",
        owner: 'demo@instedd.org'
      },
      "Demo Health Organization" => {
        kind: "health_organization",
        owner: 'demo_who@instedd.org'
      }
    }

    data.each do |name, props|
      Institution.find_or_create_by!(name: name) do |institution|
        owner = User.create_with(password: default_password).find_or_create_by!(email: props[:owner]) do |u|
          u.skip_confirmation!
        end
        institution.user = owner
        institution.kind = props[:kind]
      end
    end
  end
end
