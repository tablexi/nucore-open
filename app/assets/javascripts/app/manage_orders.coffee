$.fn.animateHighlight = (highlightColor, duration) ->
    highlightBg = highlightColor || "#FFFF9C"
    animateMs = duration || 2500;
    originalBg = this.css("backgroundColor")
    this.stop().css("background-color", highlightBg).animate({backgroundColor: originalBg}, animateMs)

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
    # TODO: fix clockpunch to support changes
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
      total = row.find('.cost').val() - row.find('.subsidy').val()
      row.find('.total').val(total)
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

  $('.timeinput').timeinput()
