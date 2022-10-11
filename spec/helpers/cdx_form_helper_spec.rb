require 'spec_helper'

RSpec.describe CdxFormHelper, type: :helper do
  class FooModel
    include ActiveModel::Model

    attr_accessor :foo, :bar
  end

  describe "#form_field" do
    it "basics" do
      model = FooModel.new(foo: "bar")
      cdx_form_for(model, url: "") do |form|
        rendered = form.form_field(:foo) { form.text_field :foo }
        expect(rendered).to include(%(<input type="text" value="bar" name="foo_model[foo]" id="foo_model_foo" />))
        expect(rendered).to include "Foo"
      end
    end

    it "shows error" do
      model = FooModel.new(foo: "bar")
      model.errors.add(:foo, "has an error")
      model.errors.add(:bar, "has an error")
      model.errors.add(:other, "has an error")
      model.errors.add(:base, "base error")
      cdx_form_for(model, url: "") do |form|
        rendered = form.form_field(:foo) { form.text_field :foo }
        expect(rendered).to include("Foo has an error")
        expect(rendered).not_to include("Bar has an errror")
        form.form_errors(ignore_unhandled: true)
      end
    end
  end

  describe "#form_errors" do
    it "shows all error messages" do
      model = FooModel.new(foo: "bar")
      model.errors.add(:base, "base error")
      model.errors.add(:other, "has an error")
      cdx_form_for(model, url: "") do |form|
        rendered = form.form_errors(ignore_unhandled: true)
        expect(rendered).to include("base error")
        expect(rendered).to include("Other has an error")
      end
    end

    it "remembers error messages that have been displayed" do
      model = FooModel.new(foo: "bar")
      model.errors.add(:foo, "has an error")
      model.errors.add(:base, "base error")
      model.errors.add(:other, "has an error")
      cdx_form_for(model, url: "") do |form|
        form.form_field(:foo) {}
        rendered = form.form_errors(ignore_unhandled: true)
        expect(rendered).to include("base error")
        expect(rendered).to include("Other has an error")
        expect(rendered).not_to include("Foo has an errror")
      end
    end

    it "renders errors only once" do
      model = FooModel.new(foo: "bar")
      model.errors.add(:foo, "has an error")
      cdx_form_for(model, url: "") do |form|
        rendered = form.form_errors(ignore_unhandled: true)
        expect(rendered).to include("Foo has an error")

        rendered = form.form_errors
        expect(rendered).to be_blank
      end
    end

    it "renders errors implicitly" do
      model = FooModel.new(foo: "bar")
      model.errors.add(:base, "Has an error")
      rendered = cdx_form_for(model, url: "") { }
      expect(rendered).to include("Has an error")
    end

    it "raises for unhandled error" do
      model = FooModel.new(foo: "bar")
      model.errors.add(:foo, "has an error")
      cdx_form_for(model, url: "") do |form|
        expect { form.form_errors }.to raise_error(%(Unhandled form errors in FooModel: {:foo=>["Foo has an error"]}))
      end
    end
  end

  describe "#fields_for" do
    it "handles nested error messages" do
      bar = FooModel.new(bar: "baz")
      bar.errors.add(:base, "Has an error")
      bar.errors.add(:bar, "has an error")
      model = FooModel.new(bar: bar)
      model.errors.add(:"bar.base", "Has an error")
      model.errors.add(:"bar.bar", "has an error")
      cdx_form_for(model, url: "") do |form|
        expect(
          form.fields_for(:bar) do |foo_form|
            expect(
              foo_form.form_field(:bar) { foo_form.text_field :bar }
            ).to include("Bar has an error")
          end
        ).to include("Has an error")
      end
    end

    it "raises for unhandled nested errror" do
      bar = FooModel.new(bar: "baz")
      model = FooModel.new(foo: "foo", bar: bar)
      bar.errors.add(:base, "has an error")
      bar.errors.add(:bar, "is empty")
      expect(
        cdx_form_for(model, url: "") do |form|
          expect { form.fields_for(:bar) {} }.to raise_error(%{Unhandled form errors in FooModel: {:bar=>["Bar is empty"]}})
        end
      ).not_to include("is empty")
    end

    it "raises for unhandled nested errror" do
      bar = FooModel.new(bar: "baz")
      model = FooModel.new(foo: "foo", bar: bar)
      bar.errors.add(:base, "has an error")
      expect(
        cdx_form_for(model, url: "") do |form|
          expect(
            form.fields_for(:bar) {}
          ).to include("has an error")
        end
      ).not_to include("has an error")
    end

    it "doesn't hide unknown errors" do
      bar = FooModel.new(bar: "baz")
      model = FooModel.new(foo: "foo", bar: bar)
      model.errors.add(:"bar.unknown", "has an error")
      expect do
        cdx_form_for(model, url: "") do |form|
          form.fields_for(:bar) {}
        end
      end.to raise_error(%{Unhandled form errors in FooModel: {:"bar.unknown"=>["Bar unknown has an error"]}})
    end
  end
end
