require File.expand_path("../../test_helper", __FILE__)

module MipiseClient
  class ChargeTest < Test::Unit::TestCase

    should "create a new charge" do
      token = "some_token"
      access_token = "test_access_token"
      amount_in_cents = 2000

      MipiseClient.expects(:execute_request).with(has_entry(:payload, "access_token=#{access_token}&amount_in_cents=#{amount_in_cents}&token=#{token}")).returns(make_response(make_charge))
      MipiseClient::Charge.create(
                            token: token,
                            access_token: access_token,
                            amount_in_cents: amount_in_cents
      )

    end

  end
end