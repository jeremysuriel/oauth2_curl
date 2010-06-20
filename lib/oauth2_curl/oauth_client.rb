module Oauth2Curl
  class OAuthClient
    class << self
      def rcfile(reload = false)
        if reload || @rcfile.nil?
          @rcfile = RCFile.new
        end
        @rcfile
      end

      def load_from_options(options)
        if rcfile.has_oauth_profile_for_username_with_consumer_key?(options.username, options.consumer_key)
          load_client_for_username_and_consumer_key(options.username, options.consumer_key)
        elsif options.username || (options.command == 'authorize')
          load_new_client_from_options(options)
        else
          load_default_client
        end
      end

      def load_client_for_username_and_consumer_key(username, consumer_key)
        user_profiles = rcfile[username]
        if user_profiles && attributes = user_profiles[consumer_key]
          new(attributes)
        else
          raise Exception, "No profile for #{username}"
        end
      end

      def load_client_for_username(username)
        if user_profiles = rcfile[username]
          if user_profiles.values.size == 1
            new(user_profiles.values.first)
          else
            raise Exception, "There is more than one consumer key associated with #{username}. Please specify which consumer key you want as well."
          end
        else
          raise Exception, "No profile for #{username}"
        end
      end

      def load_new_client_from_options(options)
        new(options.oauth_client_options.merge('password' => options.password))
      end

      def load_default_client
        raise Exception, "You must authorize first" unless rcfile.default_profile
        load_client_for_username_and_consumer_key(*rcfile.default_profile)
      end
    end

    OAUTH_CLIENT_OPTIONS = %w[username consumer_key consumer_secret token authorize_path access_token_path]
    attr_reader *OAUTH_CLIENT_OPTIONS
    attr_reader :password
    def initialize(options = {})
      @username        = options['username']
      @password        = options['password']
      @consumer_key    = options['consumer_key']
      @consumer_secret = options['consumer_secret']
      @token           = options['token']
      @authorize_path  = options['authorize_path'] || "/oauth/authorize"
      @access_token_path  = options['access_token_path'] || "/oauth/access_token"
      configure_http!
    end

    [:get, :post, :put, :delete, :options, :head, :copy].each do |request_method|
      class_eval(<<-EVAL, __FILE__, __LINE__)
        def #{request_method}(url, options = {})
          # configure_http!
          access_token.#{request_method}(url, options)
        end
      EVAL
    end

    def perform_request_from_options(options)
      send(options.request_method, options.path, options.data)
    end

    def exchange_credentials_for_access_token
      
      CLI.puts("Go to #{consumer.web_server.authorize_url(:redirect_uri=>Oauth2Curl.options.base_url)} and paste in the supplied PIN")
      pin = gets
      access_token = consumer.web_server.get_access_token(
        pin.chomp, :redirect_uri => "#{Oauth2Curl.options.base_url}"
      )
      
      @token = access_token.token
      CLI.puts("token: #{token}")
    end

    def client_auth_parameters
      {:x_auth_username => username, :x_auth_password => password, :x_auth_mode => 'client_auth'}
    end


    def pin_auth_parameters
      {:oauth_callback => 'oob'}
    end

    def fetch_verify_credentials
      access_token.get("#{Oauth2Curl.options.base_path}/account/verify_credentials.json")
    end

    def authorized?
      oauth_response = fetch_verify_credentials
      oauth_response.class == Net::HTTPOK
    end

    def needs_to_authorize?
      token.nil? 
    end

    def save
      verify_has_email
      self.class.rcfile << self
    end

    def verify_has_email
      if username.nil? || username == ''
        oauth_response = fetch_verify_credentials
        oauth_response =~ /"name"\s*:\s*"(.*?)"/
        @username = $1
      end
    end

    def to_hash
      OAUTH_CLIENT_OPTIONS.inject({}) do |hash, attribute|
        if value = send(attribute)
          hash[attribute] = value
        end
        hash
      end
    end

    def configure_http!
      consumer.http.set_debug_output(Oauth2Curl.options.debug_output_io) if Oauth2Curl.options.trace
      if Oauth2Curl.options.ssl?
        consumer.http.use_ssl     = true
        consumer.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    def consumer
      @consumer ||=
        OAuth2::Client.new(
          consumer_key,
          consumer_secret,
          :site => Oauth2Curl.options.base_url,
          :authorize_path => authorize_path,
          :access_token_path => access_token_path
        )
    end

    def access_token
      @access_token ||= OAuth2::AccessToken.new(consumer, token)
    end
  end
end