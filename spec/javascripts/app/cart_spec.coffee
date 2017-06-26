describe "Cart", ->
  fixture.set '
    <form class="js--cart">
      <input id="quantity" value="1">
      <a id="link" href="?quantity=16" data-quantity-field="quantity">
    </form>
  '

  beforeEach ->
    new Cart ".js--cart"

  describe "changing the quantity", ->
    it "updates the path for a positive quantity", ->
      $("#quantity").val("10").trigger("change")
      expect($("#link").attr("href")).toMatch(/quantity=10$/)

    describe "to a negative value", ->
      beforeEach ->
        $("#quantity").val("-10").trigger("change")

      it "unsets the link's href", ->
        expect($("#link").attr("href")).toBeUndefined()

      it "adds the disabled class", ->
        expect($("#link").hasClass("disabled")).toBeTruthy()

    describe "to a blank value", ->
      beforeEach ->
        $("#quantity").val(" ").trigger("change")

      it "unsets the link's href", ->
        expect($("#link").attr("href")).toBeUndefined()

      it "adds the disabled class", ->
        expect($("#link").hasClass("disabled")).toBeTruthy()

    describe "to a non-integer", ->
      beforeEach ->
        $("#quantity").val("abc").trigger("change")

      it "unsets the link's href", ->
        expect($("#link").attr("href")).toBeUndefined()

      it "adds the disabled class", ->
        expect($("#link").hasClass("disabled")).toBeTruthy()

    describe "to an invalid value and back to valid", ->
      beforeEach ->
        $("#quantity").val("-10").trigger("change")
        $("#quantity").val("17").trigger("change")

      it "sets the link's href", ->
        expect($("#link").attr("href")).toMatch(/quantity=17$/)

      it "does not have the disabled class", ->
        expect($("#link").hasClass("disabled")).toBeFalsy()
