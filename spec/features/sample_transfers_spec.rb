require "spec_helper"

describe "sample transfers" do
  describe "index" do
    let!(:my_institution) { Institution.make! }
    let!(:other_institution) { Institution.make! }
    let!(:current_user) { my_institution.user }

    before(:each) do
      sign_in(current_user)
    end

    it "shows status" do
      in_pending = SampleTransfer.make!(receiver_institution: my_institution, created_at: Time.new(2022, 3, 4))
      in_confirmed = SampleTransfer.make!(receiver_institution: my_institution, confirmed_at: Time.new(2022, 2, 24, 15, 31))
      out_pending = SampleTransfer.make!(sender_institution: my_institution, created_at: Time.new(2022, 3, 4))
      out_confirmed = SampleTransfer.make!(sender_institution: my_institution, confirmed_at: Time.new(2022, 2, 21, 12, 00))
      unrelated = SampleTransfer.make!

      goto_page ListSampleTransfersPage do |page|
        expect(page.entry(in_pending.sample.uuid)).to have_content("Confirm receipt")
        expect(page.entry(in_confirmed.sample.uuid)).to have_content("Receipt confirmed on February 24, 2022")
        expect(page.entry(out_pending.sample.uuid)).to have_content("Sent on March 04, 2022")
        expect(page.entry(out_confirmed.sample.uuid)).to have_content("Delivery confirmed on February 21, 2022")

        expect(page).not_to have_content(unrelated.sample.uuid)
      end
    end

    it "filters" do
      subject = SampleTransfer.make!(receiver_institution: my_institution)
      other = SampleTransfer.make!(receiver_institution: my_institution)

      goto_page ListSampleTransfersPage do |page|
        page.filters.sample_id.set subject.sample.uuid
        page.filters.submit
      end

      expect_page ListSampleTransfersPage do |page|
        expect(page.entry(subject.sample.uuid))

        expect(page).not_to have_content(other.sample.uuid)
      end
    end
  end
end
