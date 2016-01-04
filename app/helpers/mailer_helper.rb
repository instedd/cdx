module MailerHelper
  def absolute_url(url)
    if URI.parse(url).absolute?
      url
    else
      "http://#{Settings.host}" + url
    end
  end
end
