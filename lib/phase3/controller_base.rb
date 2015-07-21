require_relative '../phase2/controller_base'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'

module Phase3
  class ControllerBase < Phase2::ControllerBase
    # use ERB and binding to evaluate templates
    # pass the rendered html to render_content
    def render(template_name)
      template_file = File.read("views/#{self.class.to_s.underscore}/#{template_name}.html.erb")
      template = ERB.new(template_file).result(binding) # eval needed later on?
      render_content(template, 'text/html')
    end
  end
end
