# Rails + ActiveRecord Lite
A lightweight ORM + MVC framework inspired by Rails and ActiveRecord.

## How to Use
- Clone this repo.
- Run `ruby bin/server.rb` to start the server.
- Navigate to `localhost:3000/cats`.
- Define new routes at the end of `server.rb`, in the `router.draw` block. One route per line, four arguments in order: HTTP method, Regexp matching the desired URL pattern, controller name, action method to invoke as a symbol. Any groups defined in the regex will be parsed as route params and passed on to the controller. *i.e.* the ID found in a URL matching `/cats/(?<cat_id>\\d+)` is accessible through params[:cat_id] in the controller.
- New models and controllers should be defined in `server.rb`. Models inherit from SQLObject; controllers from ControllerBase.
- New views should be placed in `views/#{controller_name}_controller` and named according to the corresponding RESTful action which renders them. (index.html.erb, show.html.erb...)

## Implementation Details
### SQLObject
The base class for anything persisted to the database.
- Auto-defines getter and setter methods for column entries. Be sure to call `self.finalize!` when creating a new SQLObject, otherwise these methods won't be defined.
- Implements `find(id)`, `save`, `insert`, and `update` on its own.
- Searchable and Associatable modules implement `where`, `belongs_to`, `has_many`, and `has_one_through`, with options to use Rails-like table names and primary/foreign keys, or override the defaults where ActiveSupport would get confused, *e.g.* `human.pluralize` => 'humen'. Use these like you would the corresponding ActiveRecord methods.

### Router and Route
Receives HTTP requests and routes them to the appropriate controller and action.
- Auto-defines RESTful GET/POST/PUT/DELETE methods for a given controller class.
- Each new Route stores a reference to its controller class and method name.
- `Router#draw` supports Rails-like block syntax to define routes.

### ControllerBase
Receives HTTP requests from the router and renders the appropriate response.
- Uses `send` to invoke a RESTful action after its calling Route instantiates it.
- Renders HTML content with ERB, conforming strictly to Rails-style filename conventions for template names.
- Implements basic CSRF protection by setting a Base64 authenticity token after each action, and raising an error for POST actions if the cookie's token fails to match the parameters' token.
- Implements Flash and Flash.now for message display scoped to an HTTP redirect or view re-render.

#### Params
Parses the request URL, query string, and route parameters into a hash object. Accepts Rails-like nested hash syntax for parsing URI-encoded form data, and implements bracket-style hash access by string or symbol names for a given parameter key.
- *ex.* `foo[bar][baz]=spam&foo[bar][quux]=eggs => { foo: { bar: { baz: spam, quux: eggs } } }`

#### Session
Handles cookie storage and retrieval to/from JSON data. Each ControllerBase implements a `session` method which exposes a Session object; set and retrieve values for the response cookie with Session#[] and Session#[]=. Call Session#store_session, passing the HTTP response, to send your cookie to the client.

#### Flash
Flashes are implemented here in a separate `_rails_lite_flash` cookie rather than in Sessions' `_rails_lite_app`.
- the Hash object `@flash_now` stores the parsed request cookie (from JSON) if it exists; `@flash_later` stores the response data.
- Bracket methods work slightly differently compared to Session; Flash#[] accesses `@flash_now`, but Flash#[]= sets a value on `@flash_later`.
- Use Flash#now to access the `@flash_now` Hash object directly. Bracket setters and getters here (*eg* `flash.now[:foo]`) are Hash methods.
