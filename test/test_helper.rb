require 'mipise_client'
require 'test/unit'
require 'shoulda'
require 'mocha/setup'

module MipiseClient
  @mock_rest_client = nil

  def self.mock_rest_client=(mock_client)
    @mock_rest_client = mock_client
  end

  class << self
    remove_method :execute_request
  end

  def self.execute_request(params)
    get_params = (params[:headers] || {})[:params]
    post_params = params[:payload]
    case params[:method]
      when :get then @mock_rest_client.get params[:url], get_params, post_params
      when :post then @mock_rest_client.post params[:url], get_params, post_params
      when :delete then @mock_rest_client.delete params[:url], get_params, post_params
    end
  end

  class Test::Unit::TestCase
    include Mocha
    include MipiseClient::TestData

    setup do
      @mock = mock
      MipiseClient.mock_rest_client = @mock
      MipiseClient.api_platform_base = "platform_base_uri"
      MipiseClient.api_key = "foo"
    end

    teardown do
      MipiseClient.mock_rest_client = nil
      MipiseClient.api_platform_base = nil
      MipiseClient.api_key = nil
    end
  end
end
