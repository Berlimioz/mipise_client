module MipiseClient
  class OauthConnector

    def self.authorization_url(params)
      params[:role] = role_for(params[:role])
      params[:scope] = 'payment_platform_mipise'
      params[:response_type] = 'code'
      "#{MipiseClient.endpoint_api_url('authorize')}?#{MipiseClient::Utils.encode_parameters(params)}"
    end

    def self.authorize_for_code(code, redirect_uri)
      MipiseClient.request(:post, '/oauth/token', MipiseClient.api_key, params: {
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

