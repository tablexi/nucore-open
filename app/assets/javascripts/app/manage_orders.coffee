$.fn.animateHighlight = (options = {}) ->
  options = $.extend {}, {
      highlightClass: null
      highlightColor: "#FFFF9C",
      solidDuration: 0,
      fadeDuration: 2500 }, options
  if options.highlightClass?
    new_item = $("<div class='#{options.highlightClass}'></div>").hide().appendTo('body')
    options.highlightColor = new_item.css('backgroundColor')
    new_item.remove()

  originalBg = this.css("backgroundColor")
  this.stop()
    .css("background-color", options.highlightColor)
    .delay(options.solidDuration)
    .animate({backgroundColor: originalBg}, options.fadeDuration)


class OrderDetailManagement
  constructor: (@$element) ->
    @$element.find('.datepicker').datepicker()
    @$element.find('.timeinput').timeinput();
    @$element.find('.copy_actual_from_reservation a').click(@copyReservationTimeIntoActual)
    @init_total_calcuating()
    @init_price_updating()
    @init_cancel_fee_options()

  copyReservationTimeIntoActual: (e) ->
    e.preventDefault()
    $(this).fadeOut('fast')
    # copy each reserve_xxx field to actual_xxx
    $('[name^="order_detail[reservation][reserve_"]').each ->
      actual_name = this.name.replace(/reserve_(.*)$/, "actual_$1")
      $("[name='#{actual_name}']").val($(this).val())

    # duration_mins doesn't follow the same pattern, so do it separately
    newval = $('[name="order_detail[reservation][duration_mins]"]').val()

    $('[name="order_detail[reservation][actual_duration_mins]_display"]').val(newval).trigger('change')

  init_price_updating: ->
    self = this
    @$element.find('[name^="order_detail[reservation]"]:not([name$=_display]),[name="order_detail[quantity]"],[name="order_detail[account_id]"]').change (evt) ->
      self.update_pricing(evt)

  update_pricing: (e) ->
    self = this
    url = @$element.attr('action').replace('/manage', '/pricing')
    $.ajax {
      url: url,
      data: @$element.serialize(),
      type: 'get',
      success: (result, status) ->
        for field in ['cost', 'subsidy', 'total']

          input_field = self.$element.find("[name='order_detail[estimated_#{field}]'],[name='order_detail[actual_#{field}]']")

          old_val = input_field.val()
          new_val = result["actual_#{field}"] || result["estimated_#{field}"]
          input_field.val(new_val)
          input_field.animateHighlight() unless old_val == new_val
    }

  init_total_calcuating: ->
    self = this
    $('.cost-table .cost, .cost-table .subsidy').change ->
      row = $(this).closest('.cost-table')
      total = row.find('.cost input').val() - row.find('.subsidy input').val()
      row.find('.total input').val(total)
      self.notify_of_update $(row).find('input')


  notify_of_update: (elem) ->
    elem.animateHighlight()

  init_cancel_fee_options: ->
    $('.cancel-fee-option').hide()
    cancel_box = $('#with_cancel_fee')
    cancel_id = parseInt(cancel_box.data('show-on'))
    $(cancel_box.data('connect')).change ->
      $('.cancel-fee-option').toggle(parseInt($(this).val()) == cancel_id)

    $('#order_detail_order_status_id').change ->


$ ->
  new AjaxModal('#order-management .order-detail', '#order-detail-modal', {
    success: ->
      new OrderDetailManagement($('#order-detail-modal .edit_order_detail'))
    })

  $('.updated-order-detail').animateHighlight({ highlightClass: 'alert-info', solidDuration: 5000 })

  $('.timeinput').timeinput()
