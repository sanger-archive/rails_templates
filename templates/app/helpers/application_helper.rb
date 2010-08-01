module ApplicationHelper
  def render_flashes
    flash.each do |key, message|
      concat(content_tag(:div, message, :class => "flash", :id => "message_#{key}"))
    end
  end
end
