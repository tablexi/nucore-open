#= require helpers/jasmine-jquery

describe "Merge Orders", ->
  describe "a page that doesn't have the form", ->
    fixture.set ''
    it "does not die", ->
      new MergeOrder($(".js--edit-order")).initTimeBasedServices()

  describe "with a valid form", ->
    fixture.set '
      <form class="js--edit-order">
        <input id="quantity" class="js--edit-order__quantity" value="2" />
        <select id="product" class="js--edit-order__product">
          <option data-timed-product="false" selected="selected" value="untimed">Untimed Product</option>
          <option data-timed-product="true" value="timed">Timed Product</option>
        </select>
        <input type="text" name="duration" id="duration" class="js--edit-order__duration" value="1" />
      </form>
    '

    beforeEach ->
      new MergeOrder($(".js--edit-order")).initTimeBasedServices()

    it "does not have the duration visible", ->
      expect($("#duration")).toBeHidden()
      expect($("#duration")).toBeDisabled()

    describe "when I switch to a timed product", ->
      beforeEach ->
        $("#product").val("timed").trigger("change")

      it "will change a quantity to 1 if I switch to a timed product", ->
        expect($("#quantity").val()).toEqual("1")

      it "disables the quantity when I switch to a timed product", ->
        expect($("#quantity")).toBeDisabled()

      it "enables and shows the duration", ->
        expect($("#duration")).not.toBeDisabled()
        expect($("#duration")).toBeVisible()

      describe "and I switch back to a regular product", ->
        beforeEach ->
          $("#product").val("untimed").trigger("change")

        it "hides and disables the duration", ->
          expect($("#duration")).toBeDisabled()
          expect($("#duration")).toBeHidden()

        it "enables the quantity", ->
          expect($("#quantity")).not.toBeDisabled()




