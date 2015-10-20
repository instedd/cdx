# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
user = User.create!email: "demo-user@demo.com", password: '11111111', password_confirmation: '11111111',  confirmed_at: Time.now
institution = Institution.create! user_id: user.id, name: 'demo-institution'
site =  Site.create! institution: institution, name: 'demo-site'

device_model1 = DeviceModel.create! name: 'demo_fifo_model', published_at: 1.day.ago
manifest1 = Manifest.create! device_model: device_model1, definition: IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests', 'fio_manifest.json' ))
device1 = Device.create! site: site, institution: site.institution , name: 'demo-device_fifo', serial_number: '123',  device_model:  manifest1.device_model, time_zone: "UTC"  

device_model2 = DeviceModel.create! name: 'demo_cepheid_model', published_at: 1.day.ago
manifest2 = Manifest.create! device_model: device_model2, definition: IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests', 'cepheid_gene_xpert_manifest.json' ))
device2 = Device.create! site: site, institution: site.institution , name: 'demo-device_cepheid', serial_number: '456',  device_model:  manifest2.device_model, time_zone: "UTC"  
