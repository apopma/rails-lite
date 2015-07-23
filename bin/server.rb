require 'active_support'
require 'active_support/core_ext'
require 'webrick'

require_relative '../lib/controller_base'
require_relative '../lib/router'

# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPRequest.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPResponse.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/Cookie.html

class Cat
  attr_accessor :name, :owner

  def self.all
    @cat ||= []
  end

  def self.find(name)
    Cat.all.find { |c| c.name == name }
  end

  def initialize(params = {})
    params ||= {}
    @name, @owner = params["name"], params["owner"]
  end

  def save
    return false unless @name.present? && @owner.present?

    Cat.all << self
    true
  end

  def inspect
    { name: name, owner: owner }.inspect
  end
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
    @cat = Cat.find(params[:name])

    unless @cat
      @cat = Cat.new
      @cat.name = "nobody"
      @cat.owner = "no one"
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
  get Regexp.new("^/cats/(?<name>\\w+)$"), CatsController, :show
  get Regexp.new("^/cats/(?<cat_id>\\d+)/statuses$"), StatusesController, :index
end

server = WEBrick::HTTPServer.new(Port: 3000)
server.mount_proc('/') do |req, res|
  route = router.run(req, res)
end

trap('INT') { server.shutdown }
server.start
