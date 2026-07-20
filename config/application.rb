require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ShiftManager
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # アプリ全体で日本語をデフォルトロケールにする（バリデーションエラー等もすべて日本語化するため）
    config.i18n.default_locale = :ja

    # タイムゾーンを東京に統一する（DBは常にUTCで保存されるが、Time.current/Time.zone.now が
    # このタイムゾーンで解釈される。EB環境ではサーバーのシステム時刻がUTCのため、
    # コード側では Time.now ではなく必ず Time.current を使うこと）
    config.time_zone = "Tokyo"

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
