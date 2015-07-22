require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require 'byebug'

require_relative 'session'
require_relative 'params'
require_relative 'flash'

class ControllerBase
  attr_reader :req, :res, :params

  # setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @already_built_response = false
    @params = Params.new(req, route_params)
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  # exposes a 'Flash' object in the same way
  def flash
    @flash ||= Flash.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    dir_name = self.class.to_s.underscore
    template_file = File.read("views/#{dir_name}/#{template_name}.html.erb")
    template = ERB.new(template_file).result(binding) # eval needed later on?
    render_content(template, 'text/html')
  end

  def render_content(content, content_type)
    raise "already built response object!" if already_built_response?
    @res.content_type = content_type
    @res.body = content
    @already_built_response = true
    session.store_session(res)
    flash.store(res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def redirect_to(url)
    raise "already built response object!" if already_built_response?
    @res['location'] = url
    @res.status = 302
    @res.reason_phrase = "Redirected"
    @already_built_response = true
    session.store_session(res)
    flash.store(res)
  end

  private # ?
  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end
end
