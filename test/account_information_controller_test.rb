require File.dirname(__FILE__) + '/test_helper'

class Oauth2Curl::AccountInformationController::DispatchWithNoAuthorizedAccountsTest < Test::Unit::TestCase
  attr_reader :options, :client, :controller
  def setup
    @options    = Oauth2Curl::Options.new
    @client     = Oauth2Curl::OAuthClient.load_new_client_from_options(options)
    @controller = Oauth2Curl::AccountInformationController.new(client, options)
    mock(Oauth2Curl::OAuthClient.rcfile).empty? { true }
  end

  def test_message_indicates_when_no_accounts_are_authorized
    mock(Oauth2Curl::CLI).puts(Oauth2Curl::AccountInformationController::NO_AUTHORIZED_ACCOUNTS_MESSAGE).times(1)

    controller.dispatch
  end
end

class Oauth2Curl::AccountInformationController::DispatchWithOneAuthorizedAccountTest < Test::Unit::TestCase
  attr_reader :options, :client, :controller
  def setup
    @options    = Oauth2Curl::Options.test_exemplar
    @client     = Oauth2Curl::OAuthClient.load_new_client_from_options(options)
    mock(Oauth2Curl::OAuthClient.rcfile).save.times(1)
    Oauth2Curl::OAuthClient.rcfile << client
    @controller = Oauth2Curl::AccountInformationController.new(client, options)
  end

  def test_authorized_account_is_displayed_and_marked_as_the_default
    mock(Oauth2Curl::CLI).puts(client.username).times(1).ordered
    mock(Oauth2Curl::CLI).puts("  #{client.consumer_key} (default)").times(1).ordered

    controller.dispatch
  end
end

class Oauth2Curl::AccountInformationController::DispatchWithOneUsernameThatHasAuthorizedMultipleAccountsTest < Test::Unit::TestCase
  attr_reader :default_client_options, :default_client, :other_client_options, :other_client, :controller
  def setup
    @default_client_options = Oauth2Curl::Options.test_exemplar
    @default_client         = Oauth2Curl::OAuthClient.load_new_client_from_options(default_client_options)

    @other_client_options             = Oauth2Curl::Options.test_exemplar
    other_client_options.consumer_key = default_client_options.consumer_key.reverse
    @other_client                     = Oauth2Curl::OAuthClient.load_new_client_from_options(other_client_options)
    mock(Oauth2Curl::OAuthClient.rcfile).save.times(2)

    Oauth2Curl::OAuthClient.rcfile << default_client
    Oauth2Curl::OAuthClient.rcfile << other_client

    @controller = Oauth2Curl::AccountInformationController.new(other_client, other_client_options)
  end

  def test_authorized_account_is_displayed_and_marked_as_the_default
    mock(Oauth2Curl::CLI).puts(default_client.username).times(1)
    mock(Oauth2Curl::CLI).puts("  #{default_client.consumer_key} (default)").times(1)
    mock(Oauth2Curl::CLI).puts("  #{other_client.consumer_key}").times(1)

    controller.dispatch
  end
end