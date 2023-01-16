class BasePdf
  include Prawn::View

  def self.render(*args)
    view = new(*args)
    view.setup
    view.template
    view.render
  end

  def assets_path
    @assets_path ||= Rails.root.join("app/assets")
  end

  def setup
  end

  def template
  end
end
