require "spec_helper"

describe "transfer packages" do
  describe "transfer workflow" do
    let!(:institution_a) { Institution.make! }
    let!(:institution_b) { Institution.make! }
    let!(:user_a) { institution_a.user }
    let!(:user_b) { institution_b.user }

    it "creates transfer" do
      sample = Sample.make!(:filled, institution: institution_a)

      sign_in user_a

      goto_page NewTransferPackagePage do |page|
        expect(page).to have_content("Create Transfer Package")

        page.institution.set institution_b.name
        page.recipient.set "Santa Claus"
        page.sample_search.set sample.uuid
        page.wait_until_sample_search_visible
        expect(page.selected_sample_uuids).to eq [sample.uuid]
        page.submit
      end

      expect_page ListSampleTransfersPage do |page|
        entry = page.entry(sample.uuid)
        expect(entry.state).to have_text("Sent on")
      end

      sign_in user_b

      goto_page ListSampleTransfersPage do |page|
        expect(page).to have_content(sample.partial_uuid)

        page.entry(sample.partial_uuid).confirm.click

        page.confirm_receipt_modal.tap do |modal|
          expect(modal).to have_content("Confirm receipt")

          modal.uuid_check.set sample.uuid[-4..-1]

          modal.submit
        end
      end

      expect_page ListSampleTransfersPage do |page|
        entry = page.entry(sample.uuid)
        expect(entry.state).to have_text("Receipt confirmed")
      end
    end

    describe "sample selector" do
      before(:each) { sign_in user_a }

      it "recognizes complete UUID" do
        sample = Sample.make!(:filled, institution: institution_a)

        goto_page NewTransferPackagePage do |page|
          page.sample_search.native.send_keys sample.uuid
          page.wait_until_sample_search_visible
          expect(page.selected_sample_uuids).to eq [sample.uuid]
        end
      end

      it "search for partial UUID" do
        sample = Sample.make!(:filled, institution: institution_a)

        goto_page NewTransferPackagePage do |page|
          page.sample_search.native.send_keys sample.uuid[0, 5], :enter
          page.wait_until_sample_search_visible
          expect(page.selected_sample_uuids).to eq [sample.uuid]
        end
      end

      it "no sample found" do
        goto_page NewTransferPackagePage do |page|
          page.sample_search.native.send_keys "1", :enter
          page.wait_until_sample_search_visible
          expect(page.selected_sample_uuids).to be_empty
          expect(page).to have_content("No sample found")
        end
      end
    end
  end
end
