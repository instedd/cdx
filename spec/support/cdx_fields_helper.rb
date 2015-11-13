module CdxFieldsHelper

  def register_cdx_fields(data)
    expect(Cdx::Fields).to receive(:fields_data).and_wrap_original do |m, *args|
      m.call(*args).deep_merge("entities" => data.deep_stringify_keys)
    end.at_least(:once)
    Cdx::Fields.reload
  end

  def self.included(mod)
    mod.class_eval do
      before(:each) do
        Cdx::Fields.reload
      end
    end
  end

end
