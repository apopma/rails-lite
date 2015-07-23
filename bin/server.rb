require 'active_support'
require 'active_support/core_ext'
require 'webrick'

require_relative '../lib/controller_base'
require_relative '../lib/router'
require_relative '../lib/db/lib/sql_object'

# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPRequest.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPResponse.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/Cookie.html

class Cat < SQLObject
  belongs_to(
    :owner, class_name: "Human",
    primary_key: :id, foreign_key: :owner_id
  )
  self.finalize!
end

class Human < SQLObject
  has_many(:cats)
  self.table_name = "humans"
  self.finalize!
end

class CatsController < ControllerBase
  def create
    @cat = Cat.new(params["cat"])
    if @cat.save
      flash["notice"] = "Flash-later notice: made a new cat"
      redirect_to("/cats")
    else
      flash.now["notice"] = "Flash-now notice: something went wrong"
      render :new
    end
  end

  def index
    session["visits"] ||= 0
    session["visits"] += 1
    @cats = Cat.all
    render :index
  end

  def new
    @cat = Cat.new
    render :new
  end

  def show
    @cat = Cat.find(params[:cat_id].to_i)

    unless @cat
      @cat = Cat.new
      @cat.name = "nobody"
      @cat.owner_id = 0
    end

    render :show
  end
end

# -----------------------------------------------------------------

router = Router.new
router.draw do
  get Regexp.new("^/cats$"), CatsController, :index
  get Regexp.new("^/cats/new$"), CatsController, :new
  post Regexp.new("^/cats$"), CatsController, :create
  get Regexp.new("^/cats/(?<cat_id>\\d+)$"), CatsController, :show
end

server = WEBrick::HTTPServer.new(Port: 3000)
server.mount_proc('/') do |req, res|
  route = router.run(req, res)
end

trap('INT') { server.shutdown }
server.start
