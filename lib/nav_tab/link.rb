class NavTab::Link
  include ActionView::Helpers::UrlHelper

  attr_reader :subnav, :text, :url

  def initialize(tab_name: nil, text:, url: nil, subnav: nil, cross_facility: false)
    @tab_name = tab_name
    @text = text
    @url = url
    @subnav = subnav
    @cross_facility = cross_facility
  end

  def active?(controller)
    return false if controller.active_tab != @tab_name
    controller.all_facility? ? @cross_facility : !@cross_facility
  end

  def tab_id
    "#{@tab_name}_tab" if @tab_name.present?
  end

  def to_html
    url.present? ? link_to(text, url) : link.text
  end
end
