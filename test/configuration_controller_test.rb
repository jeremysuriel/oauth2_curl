require File.dirname(__FILE__) + '/test_helper'

class Oauth2Curl::ConfigurationController::DispatchTest < Test::Unit::TestCase
  def test_error_message_is_displayed_if_setting_is_unrecognized
    options = Oauth2Curl::Options.test_exemplar
    client  = Oauth2Curl::OAuthClient.test_exemplar

    options.subcommands = ['unrecognized', 'value']

    mock(Oauth2Curl::CLI).puts(Oauth2Curl::ConfigurationController::UNRECOGNIZED_SETTING_MESSAGE % 'unrecognized').times(1)
    mock(Oauth2Curl::OAuthClient.rcfile).save.times(0)

    controller = Oauth2Curl::ConfigurationController.new(client, options)
    controller.dispatch
  end
end

class Oauth2Curl::ConfigurationController::DispatchDefaultSettingTest < Test::Unit::TestCase
  def test_setting_default_profile_just_by_username
    options = Oauth2Curl::Options.test_exemplar
    client  = Oauth2Curl::OAuthClient.test_exemplar

    options.subcommands = ['default', client.username]
    mock(Oauth2Curl::OAuthClient).load_client_for_username(client.username).times(1) { client }
    mock(Oauth2Curl::OAuthClient.rcfile).default_profile = client
    mock(Oauth2Curl::OAuthClient.rcfile).save.times(1)

    controller = Oauth2Curl::ConfigurationController.new(client, options)
    controller.dispatch
  end

  def test_setting_default_profile_by_username_and_consumer_key
    options = Oauth2Curl::Options.test_exemplar
    client  = Oauth2Curl::OAuthClient.test_exemplar

    options.subcommands = ['default', client.username, client.consumer_key]
    mock(Oauth2Curl::OAuthClient).load_client_for_username_and_consumer_key(client.username, client.consumer_key).times(1) { client }
    mock(Oauth2Curl::OAuthClient.rcfile).default_profile = client
    mock(Oauth2Curl::OAuthClient.rcfile).save.times(1)

    controller = Oauth2Curl::ConfigurationController.new(client, options)
    controller.dispatch
  end
end