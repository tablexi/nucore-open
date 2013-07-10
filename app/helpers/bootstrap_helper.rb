module BootstrapHelper
  def modal_close_button
    content_tag :button, 'x',
      :class => 'close',
      :data => { :dismiss => 'modal' },
      'aria_hidden' => true,
      :type => 'button'
  end

  def modal_cancel_button(options = {})
    content_tag :button, 
      options[:text] || 'Cancel',
      :data => { :dismiss => 'modal' },
      :class => 'btn'
  end

  def currency_input(form, field, options = {})
    options.reverse_merge!({
      :value => number_with_precision(form.object.send(field), :precision => 2),
      :disabled => false,
      :class => ''
      })
    html = "<div class='input-prepend currency-input'><span class='add-on'>$</span>"
    html << form.text_field(field, options)
    html << '</div>'
    html.html_safe

  end
end
