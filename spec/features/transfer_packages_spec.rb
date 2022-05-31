require "spec_helper"

describe "transfer packages" do
  describe "transfer workflow" do
    let!(:institution_a) { Institution.make! }
    let!(:institution_b) { Institution.make! }
    let!(:user_a) { institution_a.user }
    let!(:user_b) { institution_b.user }

    it "creates transfer" do
      box1 = Box.make!(:filled, institution: institution_a)
      box2 = Box.make!(:filled, institution: institution_a)

      sign_in user_a

      goto_page NewTransferPackagePage do |page|
        expect(page).to have_content("Send boxes")

        page.destination.set institution_b.name
        page.recipient.set "Santa Claus"

        page.box_search.set box1.uuid
        page.wait_until_box_search_visible
        expect(page.selected_box_uuids).to eq [box1.uuid]

        page.box_search.set box2.uuid
        page.wait_until_box_search_visible
        expect(page.selected_box_uuids).to eq [box1.uuid, box2.uuid]

        page.submit
      end

      # TODO: This needs to be re-enabled when TransferPackageControler#index is implemented
      # expect_page ListBoxTransfersPage do |page|
      #   entry = page.entry(box1.uuid)
      #   expect(entry.state).to have_text("Sent on")

      #   entry = page.entry(box2.uuid)
      #   expect(entry.state).to have_text("Sent on")
      # end

      # sign_in user_b

      # goto_page ListBoxTransfersPage do |page|
      #   expect(page).to have_content(box1.partial_uuid)
      #   expect(page).to have_content(box2.partial_uuid)

      #   page.entry(box1.partial_uuid).confirm.click

      #   page.confirm_receipt_modal.tap do |modal|
      #     expect(modal).to have_content("Confirm receipt")

      #     modal.uuid_check.set box1.uuid[-4..-1]

      #     modal.submit
      #   end
      # end

      # expect_page ListBoxTransfersPage do |page|
      #   entry = page.entry(box1.uuid)
      #   expect(entry.state).to have_text("Receipt confirmed")
      # end
    end

    describe "box selector" do
      before(:each) { sign_in user_a }

      it "recognizes complete UUID" do
        box = Box.make!(:filled, institution: institution_a)

        goto_page NewTransferPackagePage do |page|
          page.box_search.native.send_keys box.uuid
          page.wait_until_box_search_visible
          expect(page.selected_box_uuids).to eq [box.uuid]
        end
      end

      it "search for partial UUID" do
        box = Box.make!(:filled, institution: institution_a)

        goto_page NewTransferPackagePage do |page|
          page.box_search.native.send_keys box.uuid[0, 5], :enter
          page.wait_until_box_search_visible
          expect(page.selected_box_uuids).to eq [box.uuid]
        end
      end

      it "no box found" do
        goto_page NewTransferPackagePage do |page|
          page.box_search.native.send_keys "1", :enter
          page.wait_until_box_search_visible
          expect(page.selected_box_uuids).to be_empty
          expect(page).to have_content("No box found")
        end
      end
    end
  end
end
