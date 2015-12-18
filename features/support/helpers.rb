module Helpers
  def authenticate(user, password=nil)
    @login = HomePage.new
    @login.load
    within(@login.form) do |form|
      form.user_name.set user.email
      form.password.set password || user.password
      form.login.click
    end
  end

  def canned_policy(*args)
    institution = args[0]
    options = args.extract_options!
    site = options[:site] || '*'

    policy = <<-JSON.strip_heredoc
     {
       "statement": [
          {
            "resource": [
              "deviceModel?institution=#{institution}",
              "device?institution=#{institution}"
            ],
            "resource": [
              "site/#{site}"
            ],
            "except": [
              "deviceModel/1"
            ],
            "action": "*",
            "delegable": true
          }
        ]
      }
    JSON
    policy
  end

  def within(section)
    yield section
  end
end

World Helpers
