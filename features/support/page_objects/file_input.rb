class FileInput < SitePrism::Section
  def attach(path)
    path = Rails.root.join(path)

    Array(path).each do |p|
      raise Capybara::FileNotFound, "cannot attach file, #{p} does not exist" unless File.exist?(p.to_s)
    end

    root_element.set(path)
  end
end
