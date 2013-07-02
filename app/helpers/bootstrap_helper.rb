module BootstrapHelper
  def modal_close_button
    content_tag :button, 'x',
      :class => 'close',
      :data => { :dismiss => 'modal' },
      'aria_hidden' => true,
      :type => 'button'
  end

  def modal_cancel_button
    content_tag :button, 'Cancel',
      :data => { :dismiss => 'modal' },
      :class => 'btn'
  end
end
