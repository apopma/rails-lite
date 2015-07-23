class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  # NB: given regexes in the router are dumb and do not match trailing /
  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  # checks if pattern matches path and method matches request method
  # NB: req.request_method is sometimes a symbol and sometimes a string (?!)
  def matches?(req)
    req.request_method.downcase.to_sym == http_method && pattern =~ req.path
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  # controller expects a params hash with which to create dynamic routes
  def run(req, res)
    match_data = pattern.match req.path
    route_params = Hash[match_data.names.zip(match_data.captures)]
    controller_class.new(req, res, route_params).invoke_action(action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    instance_eval(&proc)
  end

  # make each of these methods that, when called, add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    @routes.find { |route| route.matches?(req) }
  end

  # either throw 404 or call run on a matched route
  # actually running Route#run on a successful match
  def run(req, res)
    match(req) ? match(req).run(req, res) : res.status = 404
  end
end
