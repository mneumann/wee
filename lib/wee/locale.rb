#
# Locale settings
#

require 'wee/application'
require 'wee/session'
require "fast_gettext"

include FastGettext::Translation

class Wee::Application
  class << self
    attr_accessor :text_domain
    attr_accessor :default_locale
    attr_accessor :available_locales
  end

  attr_writer :text_domain
  attr_writer :default_locale
  attr_writer :available_locales

  def text_domain
    @text_domain || self.class.text_domain
  end

  def default_locale
    @default_locale || self.class.default_locale
  end

  def available_locales
    @available_locales || self.class.available_locales
  end

  def self.load_locale(text_domain, available_locales, default_locale, params={})
    FastGettext.add_text_domain(text_domain, params)
    @text_domain = text_domain
    @available_locales = available_locales
    @default_locale = default_locale
  end
end

class Wee::Session
  attr_writer :locale

  def locale
    @locale || application.default_locale
  end

  def awake
    if lc = self.locale
      FastGettext.text_domain = application.text_domain
      FastGettext.available_locales = application.available_locales
      FastGettext.locale = lc
    end
  end
end
