require 'json'
require 'webrick'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @request_cookie = req.cookies.find { |c| c.name == "_rails_lite_app" }
    @cookie = @request_cookie ? JSON.parse(@request_cookie.value) : {}
  end

  def [](key)
    @cookie[key]
  end

  def []=(key, val)
    @cookie[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    new_cookie = WEBrick::Cookie.new("_rails_lite_app", @cookie.to_json)
    new_cookie.path = "/"
    res.cookies << new_cookie
  end
end
