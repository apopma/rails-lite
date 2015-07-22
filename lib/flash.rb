class Flash
  attr_reader :flash_now, :flash_later, :request_cookie

  def initialize(req)
    # pull out the proper cookie and store it, or a blank hash if no cookie
    @request_cookie = req.cookies.find { |c| c.name == "_rails_lite_flash" }
    @flash_now = @request_cookie ? JSON.parse(request_cookie.value) : {}
    @flash_later = {}
  end

  def [](key)
    # SETTING a flash can be either now or later,
    # but viewing a flash in a view is always now, not later
    flash_now[key]
  end

  def []=(key, val)
    @flash_later[key] = val
  end

  def now
    # aliases this hash - flash.now[] calls Hash bracket methods, not Flash
    flash_now
  end

  def store(res)
    new_cookie = WEBrick::Cookie.new("_rails_lite_flash", flash_later.to_json)
    new_cookie.path = "/"
    res.cookies << new_cookie
  end
end
