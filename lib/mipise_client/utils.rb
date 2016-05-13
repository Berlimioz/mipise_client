module MipiseClient
  module Utils
    def self.objects_to_ids(h)
      case h
        when Hash
          res = {}
          h.each { |k,v| res[k] = objects_to_ids(v) unless v.nil? }
          res
        when Array
          h.map { |v| objects_to_ids(v) }
        else
          h
      end
    end

    def self.object_classes
      @object_classes ||= {
        # business objects
        'charge' => Charge
      }
    end

    def self.symbolize_names(object)
      case object
        when Hash
          new_hash = {}
          object.each do |key, value|
            key = (key.to_sym rescue key) || key
            new_hash[key] = symbolize_names(value)
          end
          new_hash
        when Array
          object.map { |value| symbolize_names(value) }
        else
          object
      end
    end

    def self.convert_to_stripe_object(resp, opts)
      case resp
        when Array
          resp.map { |i| convert_to_stripe_object(i, opts) }
        when Hash
          # Try converting to a known object class.  If none available, fall back to generic StripeObject
          object_classes.fetch(resp[:object], StripeObject).construct_from(resp, opts)
        else
          resp
      end
    end

    # Encodes a hash of parameters in a way that's suitable for use as query
    # parameters in a URI or as form parameters in a request body. This mainly
    # involves escaping special characters from parameter keys and values (e.g.
    # `&`).
    def self.encode_parameters(params)
      Utils.flatten_params(params).
        map { |k,v| "#{url_encode(k)}=#{url_encode(v)}" }.join('&')
    end

    # Encodes a string in a way that makes it suitable for use in a set of
    # query parameters in a URI or in a set of form parameters in a request
    # body.
    def self.url_encode(key)
      CGI.escape(key.to_s).
        # Don't use strict form encoding by changing the square bracket control
        # characters back to their literals. This is fine by the server, and
        # makes these parameter strings easier to read.
        gsub('%5B', '[').gsub('%5D', ']')
    end

    def self.flatten_params(params, parent_key=nil)
      result = []

      # do not sort the final output because arrays (and arrays of hashes
      # especially) can be order sensitive, but do sort incoming parameters
      params.sort_by { |(k, _)| k.to_s }.each do |key, value|
        calculated_key = parent_key ? "#{parent_key}[#{key}]" : "#{key}"
        if value.is_a?(Hash)
          result += flatten_params(value, calculated_key)
        elsif value.is_a?(Array)
          result += flatten_params_array(value, calculated_key)
        else
          result << [calculated_key, value]
        end
      end

      result
    end

  end

  def self.flatten_params_array(value, calculated_key)
    result = []
    value.each do |elem|
      if elem.is_a?(Hash)
        result += flatten_params(elem, "#{calculated_key}[]")
      elsif elem.is_a?(Array)
        result += flatten_params_array(elem, calculated_key)
      else
        result << ["#{calculated_key}[]", elem]
      end
    end
    result
  end
end
