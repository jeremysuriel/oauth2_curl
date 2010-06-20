require File.dirname(__FILE__) + '/test_helper'

class Oauth2Curl::RequestController::AbstractTestCase < Test::Unit::TestCase
  attr_reader :options, :client, :controller
  def setup
    Oauth2Curl::CLI.output = StringIO.new
    @options    = Oauth2Curl::Options.test_exemplar
    @client     = Oauth2Curl::OAuthClient.test_exemplar
    @controller = Oauth2Curl::RequestController.new(client, options)
  end

  def teardown
    super
    Oauth2Curl::CLI.output = STDOUT
  end

  def test_nothing
    # Appeasing test/unit
  end
end

class Oauth2Curl::RequestController::DispatchTest < Oauth2Curl::RequestController::AbstractTestCase
  def test_request_will_be_made_if_client_is_authorized
    mock(client).needs_to_authorize? { false }.times(1)
    mock(controller).perform_request.times(1)

    controller.dispatch
  end

  def test_request_will_not_be_made_if_client_is_not_authorized
    mock(client).needs_to_authorize? { true }.times(1)
    mock(controller).perform_request.never

    assert_raises Oauth2Curl::Exception do
      controller.dispatch
    end
  end
end

class Oauth2Curl::RequestController::RequestTest < Oauth2Curl::RequestController::AbstractTestCase
  def test_request_response_is_written_to_output
    expected_body = 'this is a fake response body'
    response      = Object.new
    mock(response).body.times(1) { expected_body }
    mock(client).perform_request_from_options(options).times(1) { response }

    controller.perform_request

    assert_equal expected_body, Oauth2Curl::CLI.output.string.chomp
  end

  def test_invalid_or_unspecified_urls_report_error
    mock(Oauth2Curl::CLI).puts(Oauth2Curl::RequestController::NO_URI_MESSAGE).times(1)
    mock(client).perform_request_from_options(options).times(1) { raise URI::InvalidURIError }

    controller.perform_request
  end
end