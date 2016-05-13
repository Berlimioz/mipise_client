module MipiseClient
  class Charge
    attr_accessor :id

    def initialize(id)
      @id = id
    end

    def self.create(params={}, opts={})
      res = MipiseClient.request(:post, '/backers', MipiseClient.api_key, params: params)[0]
      self.new(res['payment_token'])
    end

  end
end
