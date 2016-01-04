require 'spec_helper'

RSpec.describe MailerHelper, type: :helper do
  describe "absolute_url" do
    it "should not touch if host present" do
      expect(helper.absolute_url("http://example.org/foo/bar")).to eq("http://example.org/foo/bar")
    end

    it "should append settings host if no host" do
      expect(Settings.host).to eq("localhost:3000")
      expect(helper.absolute_url("/foo/bar")).to eq("http://localhost:3000/foo/bar")
    end
  end
end
