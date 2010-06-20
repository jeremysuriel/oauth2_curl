require File.dirname(__FILE__) + '/test_helper'

class Oauth2Curl::AliasesController::DispatchTest < Test::Unit::TestCase
  attr_reader :options, :client
  def setup
    @options = Oauth2Curl::Options.test_exemplar
    @client  = Oauth2Curl::OAuthClient.test_exemplar

    # Clean slate
    if Oauth2Curl::OAuthClient.rcfile.aliases
      Oauth2Curl::OAuthClient.rcfile.aliases.clear
    end

    stub(Oauth2Curl::OAuthClient.rcfile).save
  end

  def test_when_no_subcommands_are_provided_and_no_aliases_exist_nothing_is_displayed
    assert options.subcommands.empty?
    mock(Oauth2Curl::CLI).puts(Oauth2Curl::AliasesController::NO_ALIASES_MESSAGE).times(1)

    controller = Oauth2Curl::AliasesController.new(client, options)
    controller.dispatch
  end

  def test_when_no_subcommands_are_provided_and_aliases_exist_they_are_displayed
    assert options.subcommands.empty?

    Oauth2Curl::OAuthClient.rcfile.alias('h', '/1/statuses/home_timeline.xml')
    mock(Oauth2Curl::CLI).puts("h: /1/statuses/home_timeline.xml").times(1)

    controller = Oauth2Curl::AliasesController.new(client, options)
    controller.dispatch
  end

  def test_when_alias_and_value_are_provided_they_are_added
    options.subcommands = ['h']
    options.path        = '/1/statuses/home_timeline.xml'
    mock(Oauth2Curl::OAuthClient.rcfile).alias('h', '/1/statuses/home_timeline.xml').times(1)

    controller = Oauth2Curl::AliasesController.new(client, options)
    controller.dispatch
  end

  def test_when_no_path_is_provided_nothing_happens
    options.subcommands = ['a']
    assert_nil options.path

    mock(Oauth2Curl::CLI).puts(Oauth2Curl::AliasesController::NO_PATH_PROVIDED_MESSAGE).times(1)

    controller = Oauth2Curl::AliasesController.new(client, options)
    controller.dispatch
  end
end