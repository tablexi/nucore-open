class OrderDetailManagement
  constructor: (@$element) ->
    @$element.find('.datepicker').datepicker()
    @$element.find('.timeinput').timeinput();
    @$element.find('.copy_actual_from_reservation a').click(@copyReservationTimeIntoActual)

  copyReservationTimeIntoActual: (e) ->
    e.preventDefault()
    # copy each reserve_xxx field to actual_xxx
    $('[name^="order_detail[reservation][reserve_"]').each ->
      actual_name = this.name.replace(/reserve_(.*)$/, "actual_$1")
      $("[name='#{actual_name}']").val($(this).val())

    # duration_mins doesn't follow the same pattern, so do it separately
    newval = $('[name="order_detail[reservation][duration_mins]"]').val()
    # TODO: fix clockpunch to support changes
    $('[name="order_detail[reservation][actual_duration_mins]_display"]').val(newval).trigger('change')


$ ->
  new OrderDetailManagement($('.edit_order_detail'))
