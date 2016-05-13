module MipiseClient
  class OauthConnector

    def self.authorization_url(params)
      params[:role] = role_for(params[:role])
      params[:scope] = 'payment_platform_mipise'
      params[:response_type] = 'code'
      #http://metalabo.mipise.dev/en/api/v1/oauth/authorize?client_id=MI-CI705-U41826-ID723664&state=3&response_type=code&scope=payment_platform_mipise&redirect_uri=https://metalabo.org/mipise_connect/client
      "#{MipiseClient.endpoint_api_url('authorize')}?#{MipiseClient::Utils.encode_parameters(params)}"
    end

    def self.authorize_for_code(code, redirect_uri)
      MipiseClient.request(:post, '/oauth/authorize', MipiseClient.api_key, params: {
                                                       code: code,
                                                       grant_type: 'authorization_code',
                                                       redirect_uri: redirect_uri})[0]

    end

    private

    def self.role_for(role)
      case role.to_s
        when 'beneficiary' then 'payment_partner_beneficiary'
        when 'sub_beneficiary' then 'payment_project_beneficiary'
        else
          raise "Invalid role : #{role}. Should be one of 'beneficiary' or 'sub_beneficiary'"
      end
    end

  end
end

