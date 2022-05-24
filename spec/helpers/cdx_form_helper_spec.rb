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
        expect { form.form_errors }.to raise_error(%(Unhandled form errors in foo_model: {:foo=>["Foo has an error"]}))
      end
    end
  end

  describe "#fields_for" do
    it "handles nested error messages" do
      foo = FooModel.new(bar: "bar")
      model = FooModel.new(foo: foo)
      model.errors.add(:"foo.bar", "has an error")
      rendered = cdx_form_for(model, url: "") do |form|
        form.fields_for(:foo) do |foo_form|
          rendered = foo_form.form_field :bar
          expect(rendered).to include("Foo bar has an error")
        end
      end
    end

    it "raises for unhandled error" do
      foo = FooModel.new(bar: "bar")
      model = FooModel.new(foo: foo)
      model.errors.add(:"foo.base", "Has an error")
      model.errors.add(:"foo.foo", "is empty")
      cdx_form_for(model, url: "") do |form|
        expect { form.fields_for(:foo) {} }.to raise_error(%(Unhandled form errors in foo_model[foo]: {:"foo.base"=>["Foo base Has an error"], :"foo.foo"=>["Foo foo is empty"]}))
      end
    end
  end
end
