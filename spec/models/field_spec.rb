require "cdx/api/elasticsearch/model/field"

describe Cdx::Field do

  describe Cdx::Field::DurationField do

    let(:duration) { Cdx::Field::DurationField }

    context "Parsing strings" do

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

    context "Converting durations" do

      it "converts canonical durations" do
        expect(duration.convert_time({milliseconds: 1})).to eq(1)
        expect(duration.convert_time({seconds: 1})).to eq(1000)
        expect(duration.convert_time({minutes: 1})).to eq(60000)
        expect(duration.convert_time({hours: 1})).to eq(3600000)
        expect(duration.convert_time({days: 1})).to eq(86400000)
        expect(duration.convert_time({months: 1})).to eq(2592000000)
        expect(duration.convert_time({years: 1})).to eq(31536000000)
      end

      it "converts simple durations to milliseconds" do
        expect(duration.convert_time({milliseconds: 10})).to eq(10)
        expect(duration.convert_time({seconds: 5})).to eq(1000 * 5)
        expect(duration.convert_time({minutes: 4})).to eq(60000 * 4)
        expect(duration.convert_time({hours: 24})).to eq(3600000 * 24)
        expect(duration.convert_time({days: 35})).to eq(86400000 * 35)
        expect(duration.convert_time({months: 2})).to eq(2592000000 * 2)
        expect(duration.convert_time({years: 120})).to eq(31536000000 * 120)
      end

      it "converts compound durations to milliseconds" do
        expect(duration.convert_time({milliseconds: 10, seconds: 15})).to eq(15010)
        expect(duration.convert_time({seconds: 15, milliseconds: 10})).to eq(15010)
        expect(duration.convert_time(
          {years: 1, months: 2, days: 3, hours: 4, minutes: 5, seconds: 4, milliseconds: 6}
        )).to eq(36993904006)
      end

    end

  end

end
