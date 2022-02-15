module SpecFixtures
  def setup_fixtures(&block)
    spec = self

    # Evaluates the block in the context of the spec then generates a `#let!`
    # definition for each new instance variable. The definition will reload the
    # instance variables if needed (e.g. models).
    before :all do
      LocationService.fake!

      existing_ivars = instance_variables
      instance_eval(&block)
      new_ivars = instance_variables - existing_ivars

      new_ivars.each do |ivar|
        name = ivar.to_s[1..-1].to_sym

        spec.let!(name) do
          value = instance_variable_get(ivar)
          value.reload if value.respond_to?(:reload)
          value
        end
      end
    end

    after :all do
      DatabaseCleaner.clean_with :deletion, pre_count: true
    end
  end
end
