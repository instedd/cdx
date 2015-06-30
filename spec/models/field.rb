require "cdx/api/elasticsearch/model/field"

describe Cdx::Field do

  describe Cdx::Field::DurationField do

    let(:duration) { Cdx::Field::DurationField }

    it "parses single value durations" do
      expect(duration.parse_string "200ms").to eq({milliseconds: 200})
      expect(duration.parse_string "30s").to eq({seconds: 30})
      expect(duration.parse_string "4m").to eq({minutes: 4})
      expect(duration.parse_string "04m").to eq({minutes: 4})
      expect(duration.parse_string "2h").to eq({hours: 2})
      expect(duration.parse_string "12hs").to eq({hours: 12})
      expect(duration.parse_string "1d").to eq({days: 1})
      expect(duration.parse_string "3mo").to eq({months: 3})
      expect(duration.parse_string "5yo").to eq({years: 5})
      expect(duration.parse_string "7y").to eq({years: 7})
    end

    it "parses mixed-values durations" do
      expect(duration.parse_string "1yo3mo").to eq({years: 1, months: 3})
      expect(duration.parse_string "3mo1yo").to eq({years: 1, months: 3})
      expect(duration.parse_string "1yo2mo3d4h5m4s6ms").to eq({years: 1, months: 2, days: 3, hours: 4, minutes: 5, seconds: 4, milliseconds: 6})
    end

    it "detects malformed durations" do
      expect { duration.parse_string "1duck" }.to raise_error(RuntimeError)
      expect { duration.parse_string "1d2hs3j" }.to raise_error(RuntimeError)
    end

    pending "detects other malformed durations" do
      expect { duration.parse_string "hello" }.to raise_error(RuntimeError)
    end

  end

end
