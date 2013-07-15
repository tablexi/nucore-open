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
    @init_reconcile_note()
    @init_resolution_note()
    @disable_form() if @$element.hasClass('disabled')

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
        # Update price group text
        self.$element.find('.subsidy .help-block').text(result['price_group'])
        subsidy = result['actual_subsidy'] || result['estimated_subsidy']
        self.$element.find('.subsidy input').prop('disabled', subsidy <= 0).css('backgroundColor', '')

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
      row.find('.total input').val(total.toFixed(2))
      self.notify_of_update $(row).find('input[name*=total]')


  notify_of_update: (elem) ->
    elem.animateHighlight()

  init_cancel_fee_options: ->
    $('.cancel-fee-option').hide()
    cancel_box = $('#with_cancel_fee')
    cancel_id = parseInt(cancel_box.data('show-on'))
    $(cancel_box.data('connect')).change ->
      $('.cancel-fee-option').toggle(parseInt($(this).val()) == cancel_id)

  disable_form: ->
    form_elements = @$element.find('select,textarea,input')
    form_elements.prop 'disabled', ->
      !($(this).hasClass('js-always-enabled') || $(this).is('[type=submit]'))

    # remove the submit button if all form elements are disabled
    any_enabled = form_elements.filter(':not([type=submit])').is(':not(:disabled)')
    form_elements.filter('[type=submit]').remove() unless any_enabled

  init_reconcile_note: ->
    $('#order_detail_order_status_id').change ->
      reconciled = $(this).find('option:selected').text() == 'Reconciled'
      $('.order_detail_reconciled_note').toggle(reconciled)
    .trigger('change')

  init_resolution_note: ->
    original_button_string = $('input[type=submit]').val()
    $('#order_detail_dispute_resolved_reason').keyup ->
      if $(this).val().length > 0
        $('#order_detail_resolve_dispute').val('1')
        $('input[type=submit]').val('Resolve Dispute')
      else
        $('#order_detail_resolve_dispute').val('0')
        $('input[type=submit]').val(original_button_string)
    .trigger('keyup')


$ ->
  prepare_form = ->
    elem = $('form.manage_order_detail')
    new OrderDetailManagement(elem) if elem.length > 0

  new AjaxModal('#order-management .order-detail', '#order-detail-modal', {
    success: prepare_form
    })

  prepare_form()

  $('.updated-order-detail').animateHighlight({ highlightClass: 'alert-info', solidDuration: 5000 })

  $('.timeinput').timeinput();
  $('#product_add').chosen();
