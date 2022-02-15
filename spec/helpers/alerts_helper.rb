require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe AlertsHelper, type: :helper do
  let(:alert) { Alert.make! }

  it 'should display empty name' do
    expect(display_sites(alert)).to eq('')
  end

  it 'should display site names concatenated' do
    alert.sites << (site1 = Site.make!)
    alert.sites << (site2 = Site.make!)
    alert.sites << (site3 = Site.make!)

    expect(display_sites(alert)).to eq("#{site1.name}, #{site2.name}, #{site3.name}")
  end

  context 'alert history' do
    it 'should display an empty date' do
      expect(display_latest_alert_date(alert)).to eq('never')
    end

    it 'display_latest_alert_date' do
      begin
        Timecop.freeze(Time.utc(2013, 1, 15, 16, 32, 1))
        alert_history = AlertHistory.new
        alert_history.alert = alert
        alert_history.save
        Timecop.freeze(Time.utc(2016, 1, 16, 16, 32, 1))

        expect(display_latest_alert_date(alert)).to eq('3 years ago')
      ensure
        Timecop.return
      end
    end
  end
end
