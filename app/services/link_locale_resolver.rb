class LinkLocaleResolver
  def self.locale
    locale = I18n.locale
    locale == I18n.default_locale ? nil : locale
  end

  def self.locale_options
    I18n.locale == I18n.default_locale ? {} : { locale: I18n.locale }
  end
end
