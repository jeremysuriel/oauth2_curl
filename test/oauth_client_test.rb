require File.dirname(__FILE__) + '/test_helper'

class Oauth2Curl::OAuthClient::AbstractOAuthClientTest < Test::Unit::TestCase
  attr_reader :client, :options
  def setup
    Oauth2Curl::OAuthClient.instance_variable_set(:@rcfile, nil)

    @options                = Oauth2Curl::Options.test_exemplar
    @client                 = Oauth2Curl::OAuthClient.test_exemplar
    options.base_url        = 'api.assistly.com'
    options.request_method  = 'get'
    options.path            = '/path/does/not/matter.xml'
    options.data            = {}

    Oauth2Curl.options           = options
  end

  def teardown
    super
    Oauth2Curl.options = Oauth2Curl::Options.new
    # Make sure we don't do any disk IO in these tests
    assert !File.exists?(Oauth2Curl::RCFile.file_path)
  end

  def test_nothing
    # Appeasing test/unit
  end
end

class Oauth2Curl::OAuthClient::BasicRCFileLoadingTest < Oauth2Curl::OAuthClient::AbstractOAuthClientTest
  def test_rcfile_is_memoized
    mock.proxy(Oauth2Curl::RCFile).new.times(1)

    Oauth2Curl::OAuthClient.rcfile
    Oauth2Curl::OAuthClient.rcfile
  end

  def test_forced_reloading
    mock.proxy(Oauth2Curl::RCFile).new.times(2)

    Oauth2Curl::OAuthClient.rcfile
    Oauth2Curl::OAuthClient.rcfile(:reload)
    Oauth2Curl::OAuthClient.rcfile
  end
end

class Oauth2Curl::OAuthClient::ClientLoadingFromOptionsTest < Oauth2Curl::OAuthClient::AbstractOAuthClientTest
  def test_if_username_is_supplied_and_no_profile_exists_for_username_then_new_client_is_created
    mock(Oauth2Curl::OAuthClient).load_client_for_username(options.username).never
    mock(Oauth2Curl::OAuthClient).load_new_client_from_options(options).times(1)
    mock(Oauth2Curl::OAuthClient).load_default_client.never

    Oauth2Curl::OAuthClient.load_from_options(options)
  end

  def test_if_username_is_supplied_and_profile_exists_for_username_then_client_is_loaded
    mock(Oauth2Curl::OAuthClient.rcfile).save.times(1)
    Oauth2Curl::OAuthClient.rcfile << client

    mock(Oauth2Curl::OAuthClient).load_client_for_username_and_consumer_key(options.username, options.consumer_key).times(1)
    mock(Oauth2Curl::OAuthClient).load_new_client_from_options(options).never
    mock(Oauth2Curl::OAuthClient).load_default_client.never

    Oauth2Curl::OAuthClient.load_from_options(options)
  end

  def test_if_username_is_not_provided_then_the_default_client_is_loaded
    options.username = nil

    mock(Oauth2Curl::OAuthClient).load_client_for_username(options.username).never
    mock(Oauth2Curl::OAuthClient).load_new_client_from_options(options).never
    mock(Oauth2Curl::OAuthClient).load_default_client.times(1)

    Oauth2Curl::OAuthClient.load_from_options(options)
  end
end

class Oauth2Curl::OAuthClient::ClientLoadingForUsernameTest < Oauth2Curl::OAuthClient::AbstractOAuthClientTest
  def test_attempting_to_load_a_username_that_is_not_in_the_file_fails
    assert_nil Oauth2Curl::OAuthClient.rcfile[client.username]

    assert_raises Oauth2Curl::Exception do
      Oauth2Curl::OAuthClient.load_client_for_username_and_consumer_key(client.username, client.consumer_key)
    end
  end

  def test_loading_a_username_that_exists
    mock(Oauth2Curl::OAuthClient.rcfile).save.times(1)

    Oauth2Curl::OAuthClient.rcfile << client

    client_from_file = Oauth2Curl::OAuthClient.load_client_for_username_and_consumer_key(client.username, client.consumer_key)
    assert_equal client.to_hash, client_from_file.to_hash
  end
end

class Oauth2Curl::OAuthClient::DefaultClientLoadingTest < Oauth2Curl::OAuthClient::AbstractOAuthClientTest
  def test_loading_default_client_when_there_is_none_fails
    assert_nil Oauth2Curl::OAuthClient.rcfile.default_profile

    assert_raises Oauth2Curl::Exception do
      Oauth2Curl::OAuthClient.load_default_client
    end
  end

  def test_loading_default_client_from_file
    mock(Oauth2Curl::OAuthClient.rcfile).save.times(1)

    Oauth2Curl::OAuthClient.rcfile << client
    assert_equal [client.username, client.consumer_key], Oauth2Curl::OAuthClient.rcfile.default_profile

    client_from_file = Oauth2Curl::OAuthClient.load_default_client

    assert_equal client.to_hash, client_from_file.to_hash
  end
end

class Oauth2Curl::OAuthClient::NewClientLoadingFromOptionsTest < Oauth2Curl::OAuthClient::AbstractOAuthClientTest
  attr_reader :new_client
  def setup
    super
    @new_client = Oauth2Curl::OAuthClient.load_new_client_from_options(options)
  end

  def test_password_is_included
    assert_equal options.password, new_client.password
  end

  def test_oauth_options_are_passed_through
    assert_equal client.to_hash, new_client.to_hash
  end
end

class Oauth2Curl::OAuthClient::PerformingRequestsFromOptionsTest < Oauth2Curl::OAuthClient::AbstractOAuthClientTest
  def test_request_is_made_using_request_method_and_path_and_data_in_options
    client = Oauth2Curl::OAuthClient.test_exemplar
    mock(client).get(options.path, options.data)

    client.perform_request_from_options(options)
  end
end

class Oauth2Curl::OAuthClient::CredentialsForAccessTokenExchangeTest < Oauth2Curl::OAuthClient::AbstractOAuthClientTest
  def test_successful_exchange_parses_token_and_secret_from_response_body
    parsed_response = {:oauth_token        => "123456789",
                       :oauth_token_secret => "abcdefghi",
                       :user_id            => "3191321",
                       :screen_name        => "noradio",
                       :x_auth_expires     => "0"}

    mock(client.consumer).
      token_request(:post,
                    client.consumer.access_token_path,
                    nil,
                    {},
                    client.client_auth_parameters) { parsed_response }

   assert client.needs_to_authorize?
   client.exchange_credentials_for_access_token
   assert !client.needs_to_authorize?
  end
end