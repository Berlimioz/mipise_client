module MipiseClient
  module TestData

    def make_response(body, code=200)
      # When an exception is raised, restclient clobbers method_missing.  Hence we
      # can't just use the stubs interface.
      body = JSON.generate(body) if !(body.kind_of? String)
      m = mock
      m.instance_variable_set('@mipise_client_values', {
                                                :body => body,
                                                :code => code,
                                                :headers => {},
                                              })
      def m.body
        @mipise_client_values[:body]
      end

      def m.code
        @mipise_client_values[:code]
      end

      def m.headers
        @mipise_client_values[:headers]
      end
      m
    end

    def make_authorization(params={})
      {
        token: 'test_token',
        refresh_token: 'test_refresh_token'
      }.merge(params)
    end

    def make_charge(params={})
      {
        payment_token: "test_charge_payment_token"
      }.merge(params)
    end

  end
end