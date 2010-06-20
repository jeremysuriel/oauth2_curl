require File.dirname(__FILE__) + '/test_helper'

class Oauth2Curl::CLI::OptionParsingTest < Test::Unit::TestCase
  module CommandParsingTests
    def test_no_command_specified_falls_to_default_command
      options = Oauth2Curl::CLI.parse_options(['/1/url/does/not/matter.xml'])
      assert_equal Oauth2Curl::CLI::DEFAULT_COMMAND, options.command
    end

    def test_supported_command_specified_extracts_the_command
      expected_command = Oauth2Curl::CLI::SUPPORTED_COMMANDS.first
      options = Oauth2Curl::CLI.parse_options([expected_command])
      assert_equal expected_command, options.command
    end

    def test_unsupported_command_specified_sets_default_command
      unsupported_command = 'unsupported'
      options = Oauth2Curl::CLI.parse_options([unsupported_command])
      assert_equal Oauth2Curl::CLI::DEFAULT_COMMAND, options.command
    end
  end
  include CommandParsingTests

  module RequestMethodParsingTests
    def test_request_method_is_default_if_unspecified
      options = Oauth2Curl::CLI.parse_options(['/1/url/does/not/matter.xml'])
      assert_equal Oauth2Curl::Options::DEFAULT_REQUEST_METHOD, options.request_method
    end

    def test_specifying_a_request_method_extracts_and_normalizes_request_method
      variations = [%w[-X put], %w[-X PUT], %w[--request-method PUT], %w[--request-method put]]
      variations.each do |option_variation|
        path = '/1/url/does/not/matter.xml'
        order_variant_1 = [option_variation, path].flatten
        order_variant_2 = [path, option_variation].flatten
        [order_variant_1, order_variant_2].each do |args|
          options = Oauth2Curl::CLI.parse_options(args)
          assert_equal 'put', options.request_method
        end
      end
    end

    def test_specifying_unsupported_request_method_returns_an_error
      Oauth2Curl::CLI.parse_options(['-X', 'UNSUPPORTED'])
    end
  end
  include RequestMethodParsingTests

  module OAuthClientOptionParsingTests
    def test_extracting_the_consumer_key
      mock(Oauth2Curl::CLI).prompt_for('Consumer key').never

      options = Oauth2Curl::CLI.parse_options(['-c', 'the-key'])
      assert_equal 'the-key', options.consumer_key
    end

    def test_consumer_key_option_with_no_value_prompts_user_for_value
      mock(Oauth2Curl::CLI).prompt_for('Consumer key').times(1) { 'inputted-key'}
      options = Oauth2Curl::CLI.parse_options(['-c'])
      assert_equal 'inputted-key', options.consumer_key
    end
  end
  include OAuthClientOptionParsingTests

  module DataParsingTests
    def test_extracting_a_single_key_value_pair
      options = Oauth2Curl::CLI.parse_options(['-d', 'key=value'])
      assert_equal({'key' => 'value'}, options.data)

      options = Oauth2Curl::CLI.parse_options(['--data', 'key=value'])
      assert_equal({'key' => 'value'}, options.data)
    end

    def test_passing_data_and_no_explicit_request_method_defaults_request_method_to_post
      options = Oauth2Curl::CLI.parse_options(['-d', 'key=value'])
      assert_equal 'post', options.request_method
    end

    def test_passing_data_and_an_explicit_request_method_uses_the_specified_method
      options = Oauth2Curl::CLI.parse_options(['-d', 'key=value', '-X', 'DELETE'])
      assert_equal({'key' => 'value'}, options.data)
      assert_equal 'delete', options.request_method
    end

    def test_multiple_pairs_when_option_is_specified_multiple_times_on_command_line_collects_all
      options = Oauth2Curl::CLI.parse_options(['-d', 'key=value', '-d', 'another=pair'])
      assert_equal({'key' => 'value', 'another' => 'pair'}, options.data)
    end

    def test_multiple_pairs_separated_by_ampersand_are_all_captured
      options = Oauth2Curl::CLI.parse_options(['-d', 'key=value&another=pair'])
      assert_equal({'key' => 'value', 'another' => 'pair'}, options.data)
    end
  end
  include DataParsingTests

  module SSLDisablingTests
    def test_ssl_is_on_by_default
      options = Oauth2Curl::CLI.parse_options([])
      assert options.ssl?
    end

    def test_passing_no_ssl_option_disables_ssl
      ['-U', '--no-ssl'].each do |switch|
        options = Oauth2Curl::CLI.parse_options([switch])
        assert !options.ssl?
      end
    end
  end
  include SSLDisablingTests

  module HostOptionTests
    def test_not_specifying_host_sets_it_to_the_default
      options = Oauth2Curl::CLI.parse_options([])
      assert_equal Oauth2Curl::Options::DEFAULT_HOST, options.host
    end

    def test_setting_host_updates_to_requested_value
      custom_host = 'localhost:3000'
      assert_not_equal Oauth2Curl::Options::DEFAULT_HOST, custom_host

      [['-H', custom_host], ['--host', custom_host]].each do |option_combination|
        options = Oauth2Curl::CLI.parse_options(option_combination)
        assert_equal custom_host, options.host
      end
    end
  end
  include HostOptionTests
end