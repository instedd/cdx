require "spec_helper"

describe "sample transfers" do
  describe "index" do
    let!(:my_institution) { Institution.make! }
    let!(:other_institution) { Institution.make! }
    let!(:current_user) { my_institution.user }
    let!(:receiver_package) { TransferPackage.make receiver_institution: my_institution }
    let!(:sender_package) { TransferPackage.make sender_institution: my_institution }

    before(:each) do
      sign_in(current_user)
    end

    it "shows status" do
      in_pending = SampleTransfer.make!(transfer_package: receiver_package, created_at: Time.new(2022, 3, 4))
      in_confirmed = SampleTransfer.make!(transfer_package: receiver_package, confirmed_at: Time.new(2022, 2, 24, 15, 31))
      out_pending = SampleTransfer.make!(transfer_package: sender_package, created_at: Time.new(2022, 3, 4))
      out_confirmed = SampleTransfer.make!(transfer_package: sender_package, confirmed_at: Time.new(2022, 2, 21, 12, 00))
      unrelated = SampleTransfer.make!

      goto_page ListSampleTransfersPage do |page|
        # NOTE: can't use have_content because it may not visible (hidden by scroll)
        expect(page.entry(in_pending.sample.partial_uuid).text(:all)).to include("Unconfirmed")
        expect(page.entry(in_confirmed.sample.uuid).text(:all)).to include("Receipt confirmed on February 24, 2022")
        expect(page.entry(out_pending.sample.uuid).text(:all)).to include("Sent on March 04, 2022")
        expect(page.entry(out_confirmed.sample.uuid).text(:all)).to include("Delivery confirmed on February 21, 2022")

        expect(page).not_to have_content(unrelated.sample.partial_uuid)
      end
    end

    it "filters" do
      subject = SampleTransfer.make!(transfer_package: receiver_package)
      other = SampleTransfer.make!(transfer_package: receiver_package)

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
  end
end
