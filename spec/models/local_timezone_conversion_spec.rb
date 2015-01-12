require 'spec_helper'

describe Cdx::Api::LocalTimeZoneConversion do
  include Cdx::Api::LocalTimeZoneConversion

  describe 'converting integers and strings' do
    it { expect(convert_timezone_if_date("1")).to eq "1" }
    it { expect(convert_timezone_if_date("100")).to eq "100" }
    it { expect(convert_timezone_if_date("foo")).to eq "foo" }
  end

  describe 'converting dates' do
    context 'when there is a local timezone' do
      before { Time.zone = ActiveSupport::TimeZone["Asia/Seoul"] }
      it { expect(convert_timezone_if_date("1990-10-01")).to eq local(1990, 10, 1, 00, 00, 00) }
      it { expect(convert_timezone_if_date("1990-10-01T02:30:24")).to eq local(1990, 10, 1, 02, 30, 24) }
      it { expect(convert_timezone_if_date("1990-01-01T02:30:24Z-03:00")).to eq "1990-01-01T02:30:24Z-03:00" }
    end
    context 'when there is no local timezone' do
      before { Time.zone = nil }
      it { expect(convert_timezone_if_date("1990-10-01")).to eq "1990-10-01" }
      it { expect(convert_timezone_if_date("1990-10-01T02:30:24")).to eq "1990-10-01T02:30:24" }
      it { expect(convert_timezone_if_date("1990-01-01T02:30:24-03:00")).to eq "1990-01-01T02:30:24-03:00" }
    end
  end

  def local(*args)
    Time.zone.local(*args).iso8601
  end
end