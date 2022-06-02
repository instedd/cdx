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

      expect_page ListTransferPackagesPage do |page|
        entry = page.entries.first
        expect(entry.origin).to have_text(institution_a.name)
        expect(Date.parse(entry.transfer_date.text)).to be_today
        expect(entry.destination).to have_text(institution_b.name)
        expect(entry.recipient).to have_text("Santa Claus")
        expect(entry.state).to have_text("In transit")
      end

      sign_in user_b

      goto_page ListTransferPackagesPage do |page|
        entry = page.entries.first
        expect(entry.origin).to have_text(institution_a.name)
        expect(Date.parse(entry.transfer_date.text)).to be_today
        expect(entry.destination).to have_text(institution_b.name)
        expect(entry.recipient).to have_text("Santa Claus")
        expect(entry.state).to have_text("In transit")

        entry.uuid.click
      end

      expect_page ShowTransferPackagePage do |page|
        expect(page).to have_content("Transfer Details")

        expect(page).to have_content("Sent on")
        page.confirm_button.click
      end

      expect_page ShowTransferPackagePage do |page|
        expect(page).to have_content("Transfer Details")

        expect(page).to have_content("Sent on")
        expect(page).to have_content("Confirmed on")
        expect(page).not_to have_confirm_button
      end

      goto_page ListTransferPackagesPage do |page|
        entry = page.entries.first
        expect(entry.state).to have_text("Recieved")
      end
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
