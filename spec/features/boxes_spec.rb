require "spec_helper"

describe "boxes" do
  describe "create workflow" do
    let!(:institution) { Institution.make! }
    let!(:user) { institution.user }

    before { sign_in(user) }

    describe "with batches" do
      let(:virus_1) { Batch.make!(institution: institution, batch_number: "VIRUS-1") }
      let(:virus_2) { Batch.make!(institution: institution, batch_number: "VIRUS-2") }
      let(:distractor_1) { Batch.make!(institution: institution, batch_number: "DISTRACTOR-1") }
      let(:distractor_2) { Batch.make!(institution: institution, batch_number: "DISTRACTOR-2") }

      it "adds and removes batches and concentrations" do
        goto_page NewBoxPage do |form|
          form.fill(option: "add_batches")

          # add 2 batches:
          form.add_batch(virus_1, concentrations: [[2, 10]])
          form.add_batch(virus_2, concentrations: [[2, 10], [3, 100], [4, 1000]])
          expect(form.batch_summaries.size).to eq(2)

          # remove 1st batch:
          form.batch_summaries[0].remove_button.click
          expect(form.batch_summaries.size).to eq(1)

          # reopen batch form:
          form.batch_summaries[0].open_button.click
          batch_form = form.batch_forms[0]
          expect(batch_form.remove_concentrations.size).to eq(3)

          # remove a concentration:
          batch_form.remove_concentrations[1].click
          expect(batch_form.remove_concentrations.size).to eq(2)

          # validates replicate field:
          field = batch_form.replicate_fields[0]
          field.set(0)
          expect(batch_form.ok.disabled?).to be(true)

          field.set(5)
          expect(batch_form.ok.disabled?).to be(false)

          # validates concentration field:
          field = batch_form.concentration_fields[0]
          field.set(0)
          expect(batch_form.ok.disabled?).to be(true)

          field.set(2)
          expect(batch_form.ok.disabled?).to be(false)
        end
      end

      describe "LOD purpose" do
        it "creates the box and its samples" do
          goto_page NewBoxPage do |form|
            form.fill(purpose: "LOD", media: "Saliva", option: "add_batches")
            form.add_batch(virus_1, concentrations: [[2, 10], [3, 100], [4, 1000]])
            expect(form.batch_summaries.size).to eq(1)
            form.submit
          end

          expect_page ListBoxesPage do |page|
            expect(page.entries.size).to eq(1)
            page.entries.last.uuid.click
          end

          expect_page ShowBoxPage do |page|
            expect(page.samples.size).to eq(9)
          end
        end

        it "validates that we selected at least one batch" do
          goto_page NewBoxPage do |form|
            form.fill(purpose: "LOD", media: "Saliva", option: "add_batches")
            form.submit
          end

          expect_page CreateBoxPage do |form|
            expect(form.errors).to have_text("A batch is required")

            expect(form.purpose_field.value).to eq("LOD")
            expect(form.media_field.value).to eq("Saliva")
          end
        end
      end

      describe "Variants purpose" do
        it "creates the box and its samples" do
          goto_page NewBoxPage do |form|
            form.fill(purpose: "Variants", media: "Other", option: "add_batches")
            form.add_batch(virus_1, concentrations: [[2, 10]])
            form.add_batch(virus_2, concentrations: [[3, 20]])
            expect(form.batch_summaries.size).to eq(2)
            form.submit
          end

          expect_page ListBoxesPage do |page|
            expect(page.entries.size).to eq(1)
            page.entries.last.uuid.click
          end

          expect_page ShowBoxPage do |page|
            expect(page.samples.size).to eq(5)
          end
        end

        it "validates that we selected at least two unique batches" do
          goto_page NewBoxPage do |form|
            form.fill(purpose: "Variants", media: "Other", option: "add_batches")
            form.add_batch(virus_1, concentrations: [[1, 10]])
            form.add_batch(virus_1, concentrations: [[2, 4]])
            expect(form.batch_summaries.size).to eq(2)
            form.submit
          end

          expect_page CreateBoxPage do |form|
            expect(form.errors).to have_text("You must select at least two batches")
            expect(form.purpose_field.value).to eq("Variants")
            expect(form.media_field.value).to eq("Other")
            expect(form.batch_summaries.size).to eq(2)

            summary = form.batch_summaries[0]
            expect(summary.batch_number).to have_text(virus_1.batch_number)
            expect(summary.concentration).to have_text("1 in 1 different concentration")

            summary = form.batch_summaries[1]
            expect(summary.batch_number).to have_text(virus_1.batch_number)
            expect(summary.concentration).to have_text("2 in 1 different concentration")
          end
        end
      end

      describe "Challenge purpose" do
        it "creates a Challenge box" do
          goto_page NewBoxPage do |form|
            form.fill(purpose: "Challenge", option: "add_batches")
            form.add_batch(virus_1, concentrations: [[2, 10]])
            form.add_batch(distractor_1, concentrations: [[3, 20]], distractor: true)
            form.add_batch(distractor_2, concentrations: [[3, 20]], distractor: true)
            expect(form.batch_summaries.size).to eq(3)
            form.submit
          end

          expect_page ListBoxesPage do |page|
            expect(page.entries.size).to eq(1)
            page.entries.last.uuid.click
          end

          expect_page ShowBoxPage do |page|
            expect(page.samples.size).to eq(8)
          end
        end

        it "validates that we selected at least one distractor batch" do
          goto_page NewBoxPage do |form|
            form.fill(purpose: "Challenge", media: "Other", option: "add_batches")
            form.add_batch(virus_1, concentrations: [[1, 10]])
            form.add_batch(virus_2, concentrations: [[2, 4], [2, 4]])
            form.submit
          end

          expect_page CreateBoxPage do |form|
            expect(form.errors).to have_text("You must select at least one distractor batch")
            expect(form.purpose_field.value).to eq("Challenge")
            expect(form.batch_summaries.size).to eq(2)

            summary = form.batch_summaries[0]
            expect(summary.batch_number).to have_text(virus_1.batch_number)
            expect(summary.concentration).to have_text("1 in 1 different concentration")

            summary = form.batch_summaries[1]
            expect(summary.batch_number).to have_text(virus_2.batch_number)
            expect(summary.concentration).to have_text("4 in 1 different concentration")
          end
        end

        it "validates that we selected at least one virus batch" do
          goto_page NewBoxPage do |form|
            form.fill(purpose: "Challenge", media: "Other", option: "add_batches")
            form.add_batch(distractor_1, concentrations: [[1, 10]], distractor: true)
            form.add_batch(distractor_2, concentrations: [[2, 4], [1, 5]], distractor: true)
            form.submit
          end

          expect_page CreateBoxPage do |form|
            expect(form.errors).to have_text("A virus batch is required")
            expect(form.purpose_field.value).to eq("Challenge")
            expect(form.batch_summaries.size).to eq(2)

            summary = form.batch_summaries[0]
            expect(summary.batch_number).to have_text(distractor_1.batch_number)
            expect(summary.concentration).to have_text("1 in 1 different concentration")
            # TODO: expect that sumary.distractor is checked

            summary = form.batch_summaries[1]
            expect(summary.batch_number).to have_text(distractor_2.batch_number)
            expect(summary.concentration).to have_text("3 in 2 different concentrations")
            # TODO: expect that sumary.distractor is checked
          end
        end
      end

      describe "Other purpose" do
        xit "creates an Other box" do
        end
      end
    end

    describe "with samples" do
      xit "creates the box" do
      end
    end
  end
end
