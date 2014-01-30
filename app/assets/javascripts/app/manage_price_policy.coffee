class window.RateWatcher
  @rateClass = '.usage_rate'
  @adjustClass = '.usage_adjustment'


  constructor: ->
    @masterClass = '.master_usage_cost'
    @rateClass = this.constructor.rateClass
    @adjustClass = this.constructor.adjustClass
    @setupRates()
    @setupAdjustments()


  setupRates: ->
    $(@rateClass).each (i, elem)=> @showRatePerMinute $(elem)
    $(@rateClass).bind 'keyup', (e)=> @showRatePerMinute $(e.target)


  updateAdjustments: ->
    $(@adjustClass).each (i, elem)=> @showAdjustmentPerMinute $(elem)


  setupAdjustments: ->
    @updateAdjustments()
    $(@adjustClass).bind 'keyup', (e)=> @showAdjustmentPerMinute $(e.target)
    $(@masterClass).bind 'keyup', => @updateAdjustments()


  showRatePerMinute: ($input)->
    @displayRate $input, $input.val() / 60


  showAdjustmentPerMinute: ($input)->
    masterVal = $(@masterClass).val()
    @displayRate $input, (masterVal - $input.val()) / 60


  hasValue: ($input)->
    $input.is(':not(:disabled)') and $input.val() > 0


  displayRate: ($input, rate)->
    $input.next('.per-minute').remove()
    $input.after "<p class=\"per-minute\">$#{rate.toFixed(4)} / minute</p>" if @hasValue($input)


$ ->
  target = "#{RateWatcher.rateClass},#{RateWatcher.adjustClass}"
  new RateWatcher() if $(target).length

