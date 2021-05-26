module TwoFactorAuthentication
  class SelectionPresenter
    include ActionView::Helpers::TranslationHelper

    attr_reader :configuration

    def initialize(configuration = nil)
      @configuration = configuration
    end

    def type
      method.to_s
    end

    def label
      t("two_factor_authentication.#{option_mode}.#{method}")
    end

    def info
      t("two_factor_authentication.#{option_mode}.#{method}_info_html")
    end

    def security_level; end

    def html_class
      ''
    end

    private

    def option_mode
      @configuration.present? ? 'login_options' : 'two_factor_choice_options'
    end
  end
end
