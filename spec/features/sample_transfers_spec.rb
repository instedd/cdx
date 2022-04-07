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
        # NOTE: can't use have_content because it may not visible (hidden by scroll)
        expect(page.entry(in_pending.sample.partial_uuid).text(:all)).to include("Confirm receipt")
        expect(page.entry(in_confirmed.sample.uuid).text(:all)).to include("Receipt confirmed on February 24, 2022")
        expect(page.entry(out_pending.sample.uuid).text(:all)).to include("Sent on March 04, 2022")
        expect(page.entry(out_confirmed.sample.uuid).text(:all)).to include("Delivery confirmed on February 21, 2022")

        expect(page).not_to have_content(unrelated.sample.partial_uuid)
      end
    end

    it "filters" do
      subject = SampleTransfer.make!(receiver_institution: my_institution)
      other = SampleTransfer.make!(receiver_institution: my_institution)

      goto_page ListSampleTransfersPage do |page|
        page.filters.sample_id.set subject.sample.uuid
      end

      expect_page ListSampleTransfersPage do |page|
        expect(page.entry(subject.sample.partial_uuid))

        expect(page).not_to have_content(other.sample.partial_uuid)
      end
    end
  end

  describe "transfer workflow" do
    let!(:institution_a) { Institution.make! }
    let!(:institution_b) { Institution.make! }
    let!(:user_a) { institution_a.user }
    let!(:user_b) { institution_b.user }

    pending "pending due to JS driver incompatibility (#1426)" do
      sample = Sample.make!(:filled, institution: institution_a)

      sign_in user_a

      goto_page ListSamplesPage do |page|
        page.entry(sample.uuid).select
        page.actions.bulk_transfer.click

        page.bulk_transfer_modal.tap do |modal|
          expect(modal).to have_content("Transfer samples")
          modal.institution.set institution_b.name
          modal.submit
        end
      end

      expect_page ListSamplesPage do |page|
        expect(page).not_to have_content(sample.uuid)
      end

      sign_in user_b

      goto_page ListSampleTransfersPage do |page|
        expect(page).to have_content(sample.partial_uuid)

        page.entry(sample.partial_uuid).find_link("Confirm receipt").click

        page.confirm_receipt_modal.tap do |modal|
          expect(modal).to have_content("Confirm receipt")

          modal.uuid_check.set sample.uuid[-4..-1]

          modal.submit
        end
      end

      expect_page ListSampleTransfersPage do |page|
        expect(page).not_to have_content(sample.partial_uuid)
      end

      goto_page ListSamplesPage do |page|
        expect(page).to have_content(sample.uuid)
      end
    end

    it "verifies sample id" do
      sample = Sample.make!(:filled, institution: institution_a)
      transfer = TransferPackage.sending_to(institution_b).add!(sample)

      sign_in user_b

      goto_page ListSampleTransfersPage do |page|
        page.entry(sample.partial_uuid).find_link("Confirm receipt").click

        page.confirm_receipt_modal.tap do |modal|
          expect(modal).to have_content("Confirm receipt")

          expect(modal).not_to have_content("Invalid sample ID")
          expect(modal).not_to have_submit_button

          modal.uuid_check.set "a"
          expect(modal).not_to have_content("Invalid sample ID")
          expect(modal).not_to have_submit_button

          modal.uuid_check.set "x"
          expect(modal).to have_content("Invalid sample ID")
          expect(modal).not_to have_submit_button

          modal.uuid_check.set "xxxx"
          expect(modal).to have_content("Invalid sample ID")
          expect(modal).not_to have_submit_button

          modal.uuid_check.set "1111"
          expect(modal).to have_content("Invalid sample ID")
          expect(modal).not_to have_submit_button

          modal.uuid_check.set sample.uuid[-4..-1]
          expect(modal).not_to have_content("Invalid sample ID")
          expect(modal).to have_submit_button

          modal.submit
        end
      end

      transfer.reload
      expect(transfer).to be_confirmed
    end
  end
end
