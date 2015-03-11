shared_context "skip manifest validation", validate_manifest: false do

  before(:each) do
    Manifest.any_instance.stub(:manifest_validation)
  end

end
