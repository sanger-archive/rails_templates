module ApplicationHelper
  def render_flashes
    output = ""
    flash.each do |key, message|
      output = output + content_tag(:div, message, :class => "flash", :id => "message_#{key}")
    end
    return output
  end
end
