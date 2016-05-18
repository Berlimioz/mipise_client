require 'rest-client'
require 'socket'
require 'json'
#require 'set'

require "mipise_client/version"
require 'mipise_client/utils'
require 'mipise_client/charge'
require 'mipise_client/oauth_connector'

module MipiseClient
  @api_version = "v1"
  @verify_ssl_certs = true
  @ca_store = nil
  @open_timeout = 30
  @read_timeout = 80

  class << self
    attr_accessor :api_key, :client_id, :api_version, :api_platform_base, :verify_ssl_certs, :ca_store, :open_timeout, :read_timeout
  end

  def self.endpoint_api_url(endpoint)
    case endpoint.to_s
      when 'payment' then api_url('/backers')
      when 'token' then api_url('/oauth/token')
      when 'authorize' then api_url('/oauth/authorize')
      else
        raise "Invalid endpoint : #{endpoint}. Should be one of 'payment', 'token' or 'authorize'"
    end
  end

  def self.api_url(url='', api_base_url: nil)
    (api_base_url || @api_platform_base) + "/api/#{@api_version}" + url
  end

  def self.request(method, url, api_key, params: {}, headers: {}, api_base_url: nil)
    api_base_url = api_base_url || @api_platform_base

    unless api_key ||= @api_key
      raise AuthenticationError.new('No API key provided. ' \
        'Set your API key using "Stripe.api_key = <API-KEY>". ' \
        'You can generate API keys from the Stripe web interface. ' \
        'See https://stripe.com/api for details, or email support@stripe.com ' \
        'if you have any questions.')
    end

    if api_key =~ /\s/
      raise AuthenticationError.new('Your API key is invalid, as it contains ' \
        'whitespace. (HINT: You can double-check your API key from the ' \
        'Stripe web interface. See https://stripe.com/api for details, or ' \
        'email support@stripe.com if you have any questions.)')
    end

    if verify_ssl_certs
      request_opts = {:verify_ssl => OpenSSL::SSL::VERIFY_PEER,
                      :ssl_cert_store => ca_store}
    else
      request_opts = {:verify_ssl => false}
      unless @verify_ssl_warned
        @verify_ssl_warned = true
        $stderr.puts("WARNING: Running without SSL cert verification. " \
          "You should never do this in production. " \
          "Execute 'Stripe.verify_ssl_certs = true' to enable verification.")
      end
    end

    params = Utils.objects_to_ids(params)
    url = api_url(url, api_base_url: api_base_url)
    case method.to_s.downcase.to_sym
      when :get, :head, :delete
        # Make params into GET parameters
        url += "#{URI.parse(url).query ? '&' : '?'}#{Utils.encode_parameters(params)}" if params && params.any?
        payload = nil
      else
        if headers[:content_type] && headers[:content_type] == "multipart/form-data"
          payload = params
        else
          payload = Utils.encode_parameters(params)
        end
    end

    request_opts.update(:headers => request_headers(api_key, method).update(headers),
                        :method => method, :open_timeout => open_timeout,
                        :payload => payload, :url => url, :timeout => read_timeout)


    response = execute_request(request_opts)

    [parse(response), api_key]
  end

  private

  def self.execute_request(params)
    RestClient::Request.execute(params)
  end

  def self.request_headers(api_key, method)
    headers = {
      #:user_agent => "Mipise/v1 RubyBindings/#{MipiseClient::VERSION}",
      :authorization => "Bearer #{api_key}",
      :content_type => 'application/x-www-form-urlencoded'
    }

    # It is only safe to retry network failures on post and delete
    # requests if we add an Idempotency-Key header
    # if [:post, :delete].include?(method) && self.max_network_retries > 0
    #   headers[:idempotency_key] ||= SecureRandom.uuid
    # end

    headers[:mipise_version] = api_version if api_version
    #headers[:mipise_account] = mipise_account if mipise_account

    #begin
      #headers.update(:x_stripe_client_user_agent => JSON.generate(user_agent))
    #rescue => e
      #headers.update(:x_stripe_client_raw_user_agent => user_agent.inspect, :error => "#{e} (#{e.class})")
    #end
    headers
  end

  def self.parse(response)
    begin
      # Would use :symbolize_names => true, but apparently there is
      # some library out there that makes symbolize_names not work.
      response = JSON.parse(response.body)
    rescue JSON::ParserError
      raise general_api_error(response.code, response.body)
    end

    Utils.symbolize_names(response)
  end
end
