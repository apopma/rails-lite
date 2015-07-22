require 'uri'
require 'byebug'

module Phase5
  class Params
    # use your initialize to merge params from
    # 1. query string
    # 2. post body
    # 3. route params
    #
    # You haven't done routing yet; but assume route params will be
    # passed in as a hash to `Params.new` as below:
    def initialize(req, route_params = {})
      @params = {}.merge!(route_params)
      parse_www_encoded_form(req.query_string) if req.query_string
      parse_www_encoded_form(req.body) if req.body
    end

    def [](key)
      # better way to do this? vOv
      @params[key.to_s] || @params[key.to_sym]
    end

    # this will be useful if we want to `puts params` in the server log
    def to_s
      @params.to_s
    end

    class AttributeNotFoundError < ArgumentError; end;

    private
    # this should return deeply nested hash
    # argument format
    # user[address][street]=main&user[address][zip]=89436
    # should return
    # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
    def parse_www_encoded_form(www_encoded_form)
      query_string = URI.decode_www_form(www_encoded_form)
      query_hash = {}

      query_string.each do |query|
        parsed_key = parse_key(query.first)
        current_hash = query_hash # same object in memory to begin with

        parsed_key.each_with_index do |nested_key, idx|
          if current_hash.key?(nested_key)
            # current_hash references query_hash on first iteration
            # always false for single query, may be true for >1 queries
            current_hash = current_hash[nested_key]
          else
            if idx == parsed_key.length - 1
              # deepest level, assign the value
              current_hash[nested_key] = query.last
            else
              # not done yet, nest a new hash
              current_hash[nested_key] = {} # actually updating query_hash
              current_hash = current_hash[nested_key] # point to new blank hash
            end
          end
        end

        @params.merge!(query_hash)
      end
    end

    # this should return an array
    # user[address][street] should return ['user', 'address', 'street']
    def parse_key(key)
      key.split(/\]\[|\[|\]/)
    end
  end
end
