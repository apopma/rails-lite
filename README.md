# Rails + ActiveRecord Lite
A lightweight ORM + MVC framework inspired by Rails and ActiveRecord.

## How to Use
- Clone this repo.
- Run `ruby bin/server.rb` to start the server.
- Navigate to `localhost:3000/cats`.

## Implementation Details
### SQLObject
The base class for anything persisted to the database.
- Auto-defines getter and setter methods for column entries. Be sure to call `self.finalize!` when creating a new SQLObject, otherwise these methods won't be defined.
- Searchable and Associatable modules implement `where`, `belongs_to`, `has_many`, and `has_one_through`, with options to use Rails-like table names and primary/foreign keys, or override the defaults where ActiveSupport would get confused, *e.g.* `human.pluralize` => 'humen'.

### Router and Route
Receives HTTP requests and routes them to the appropriate controller and action.
- Auto-defines RESTful GET/POST/PUT/DELETE methods for a given controller class.
- Each new Route stores a reference to its controller class and method name.
- `Router#draw` supports Rails-like block syntax to define routes; see bin/server.rb.

### ControllerBase
Receives HTTP requests from the router and renders the appropriate response.
- Uses `send` to invoke a RESTful action after its calling Route instantiates it.
- Renders HTML content with ERB, conforming strictly to Rails-style filename conventions for template names.
- Implements basic CSRF protection by setting a Base64 authenticity token after each action, and raising an error for POST actions if the cookie's token fails to match the parameters' token.
- Implements Flash and Flash.now for message display

#### Params

#### Flash

#### Session
