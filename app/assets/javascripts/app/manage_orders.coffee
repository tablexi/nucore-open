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
    @$element.find('.timeinput').timeinput()
    @$element.find('.copy_actual_from_reservation a').click(@copyReservationTimeIntoActual)
    @initTotalCalculating()
    @initPriceUpdating()
    @initReconcileNote()
    @initCancelFeeOptions()
    @initResolutionNote()
    @initAccountOwnerUpdate()
    @disableForm() if @$element.hasClass('disabled')
    @$element.find(".js--order-detail-price-change-reason-select").on "input", (event) ->
      selectedOption = event.target.options[event.target.selectedIndex]
      noteTextField = $(".js--order-detail-price-change-reason")
      if selectedOption.value == "Other"
        noteTextField.attr("hidden", false).val("")
      else
        noteTextField.attr("hidden", true)
        noteTextField.val(selectedOption.value)

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

  initPriceUpdating: ->
    # _display is excluded to prevent the displayed input for durations from
    # triggering. We want only the underlying quantity/mins input to trigger it.
    @$element
      .find('.js--pricingUpdate input:not([name$=_display]),.js--pricingUpdate select')
      .bind "change keyup", (evt) =>
        @updatePricing(evt) if $(evt.target).val().length > 0

    @$element.bind "reservation:times_changed", (evt) =>
      @updatePricing(evt)

  updatePricing: (e) ->
    self = this
    url = @$element.attr('action').replace('/manage', '/pricing')
    @disableSubmit()

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

        self.enableSubmit()
    }

  initTotalCalculating: ->
    self = this
    $('.cost-table .cost, .cost-table .subsidy').change ->
      row = $(this).closest('.cost-table')
      total = row.find('.cost input').val() - row.find('.subsidy input').val()
      row.find('.total input').val(total.toFixed(2))
      self.notify_of_update $(row).find('input[name*=total]')

  disableSubmit: ->
    @waiting_requests ||= 0
    @waiting_requests += 1
    @$element.find('.updating-message').removeClass('hidden')
    @$element.find('[type=submit]').prop('disabled', true)

  enableSubmit: ->
    @waiting_requests -= 1
    if @waiting_requests <= 0
      @$element.find('.updating-message').addClass('hidden')
      @$element.find('[type=submit]').prop('disabled', false)
    if @$element.find(':focus').length == 0
      @$element.find('[type=submit]').focus()

  notify_of_update: (elem) ->
    elem.animateHighlight()

  initCancelFeeOptions: ->
    $('.cancel-fee-option').hide()
    cancel_box = $('#with_cancel_fee')
    cancel_id = parseInt(cancel_box.data('show-on'))
    $(cancel_box.data('connect')).change ->
      $('.cancel-fee-option').toggle(parseInt($(this).val()) == cancel_id)

  disableForm: ->
    obj = @
    form_elements = @$element.find('select,textarea,input')
    form_elements.prop 'disabled', ->
      leaveEnabled = $(this).hasClass('js-always-enabled') || $(this).is('[type=submit]') || obj.isRailsFormInput(this)
      !leaveEnabled
    @$element.find("select.js--chosen").trigger("chosen:updated")

    # remove the submit button if all form elements are disabled (and ignore
    # Rails hidden inputs)
    any_enabled = form_elements.filter(':not([type=submit])')
      .filter(":not(#{@railsFormInputSelector})")
      .is(':not(:disabled)')
    form_elements.filter('[type=submit]').remove() unless any_enabled

  initReconcileNote: ->
    $('#order_detail_order_status_id').change ->
      reconciled = $(this).find('option:selected').text() == 'Reconciled'
      $('.order_detail_reconciled_note').toggle(reconciled)
    .trigger('change')

  initResolutionNote: ->
    $modal_save_button = @$element.find('input[type=submit]')
    original_button_string = $modal_save_button.val()
    $('#order_detail_dispute_resolved_reason').keyup ->
      if $(this).val().length > 0
        $('#order_detail_resolve_dispute').val('1')
        $modal_save_button.val('Resolve Dispute')
      else
        $('#order_detail_resolve_dispute').val('0')
        $modal_save_button.val(original_button_string)
    .trigger('keyup')

  initAccountOwnerUpdate: ->
    $('#order_detail_account_id').change ->
      owner_name = $(this).find(':selected').data('account-owner')
      $(this).closest('.control-group').find('.account-owner').text(owner_name)

  isRailsFormInput: (input) ->
    $(input).is(@railsFormInputSelector)

  railsFormInputSelector: "[name=_method],[name=utf8],[name=authenticity_token]"

$ ->
  prepareForm = ->
    elem = $('form.manage_order_detail')
    new OrderDetailManagement(elem) if elem.length > 0

  new AjaxModal('.manage-order-detail', '#order-detail-modal', {
    success: prepareForm
    })

  prepareForm()

  $('.updated-order-detail').animateHighlight({ highlightClass: 'alert-info', solidDuration: 5000 })

  $('.timeinput').timeinput()
