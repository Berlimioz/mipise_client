require File.expand_path("../../test_helper", __FILE__)

module MipiseClient
  class OauthConnectorTest < Test::Unit::TestCase
    def setup
      @client_id = 'test_mipise_client_id'
      @redirect_uri = "http://mywebsite.com/after_conect"
      @state = 'testState'
      @role = 'beneficiary'

      @params = {
        client_id: @client_id,
        redirect_uri: @redirect_uri,
        state: @state,
        role: @role
      }
    end

    should "#authorization_url should create the relevant url" do

      authorization_url = "#{MipiseClient.api_platform_base}/v1/oauth/authorize?client_id=#{@client_id}&redirect_uri=#{Utils.url_encode(@redirect_uri)}&response_type=code&role=payment_partner_beneficiary&scope=payment_platform_mipise&state=#{@state}"

      assert MipiseClient::OauthConnector.authorization_url(@params) == authorization_url
    end

    should "#authorization_url should fail with invalid role" do
      @params[:role] = "invalid_role"

      assert_raise do
        MipiseClient::OauthConnector.authorization_url(@params)
      end

    end

    should "#authorize_for_code should make a post request on the mipise api" do
      code = "testing_authorization_code"
      redirect_uri = "testing_redirect_uri"
      MipiseClient.expects(:execute_request).with(has_entry(:payload, "code=#{code}&grant_type=authorization_code&redirect_uri=#{redirect_uri}")).returns(make_response(make_authorization))

      OauthConnector.authorize_for_code(code, redirect_uri)
    end

  end

end

