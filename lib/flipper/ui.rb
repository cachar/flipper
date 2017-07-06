require 'pathname'
require 'rack'
begin
  # Rack 2
  require 'rack/method_override'
rescue LoadError
  require 'rack/methodoverride'
end
require 'rack/protection'

require 'flipper'
require 'flipper/middleware/setup_env'
require 'flipper/middleware/memoizer'
require 'flipper/ui/middleware'

module Flipper
  module UI
    class << self
      # Public: If you set this, the UI will always have a first breadcrumb that
      # says "App" which points to this href. The href can be a path (ie: "/")
      # or full url ("https://app.example.com/").
      attr_accessor :application_breadcrumb_href

      # Public: Is feature creation allowed from the UI? Defaults to true. If
      # set to false, users of the UI cannot create features. All feature
      # creation will need to be done through the conigured flipper instance.
      attr_accessor :feature_creation_enabled

      # Public: If you set this to a path to a stylesheet, you can set custom
      # styles for .environment-header and each environment as its own class.
      attr_accessor :environment_header
    end

    self.feature_creation_enabled = true

    def self.root
      @root ||= Pathname(__FILE__).dirname.expand_path.join('ui')
    end

    def self.app(flipper = nil, options = {})
      env_key = options.fetch(:env_key, 'flipper')
      app = ->() { [200, { 'Content-Type' => 'text/html' }, ['']] }
      builder = Rack::Builder.new
      yield builder if block_given?
      builder.use Rack::Protection
      builder.use Rack::Protection::AuthenticityToken
      builder.use Rack::MethodOverride
      builder.use Flipper::Middleware::SetupEnv, flipper, env_key: env_key
      builder.use Flipper::Middleware::Memoizer, env_key: env_key
      builder.use Middleware, env_key: env_key
      builder.run app
      klass = self
      builder.define_singleton_method(:inspect) { klass.inspect } # pretty rake routes output
      builder
    end
  end
end
