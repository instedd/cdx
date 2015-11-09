module CdxFieldsHelper

  def register_cdx_fields(data)
    expect(Cdx).to receive(:fields_data).and_wrap_original do |m, *args|
      m.call(*args).deep_merge(data.deep_stringify_keys)
    end
    Cdx.reload
  end

  def self.included(mod)
    mod.class_eval do
      before(:each) do
        Cdx.reload
      end
    end
  end

end
