describe "CartQuantityReplacer", ->

  describe "toString()", ->
    it "replaces the quantity a link as the only query param", ->
      subject = new CartQuantityReplacer("http://www.nucore.org?quantity=16", 13)
      expect(subject.toString()).toEqual("http://www.nucore.org?quantity=13")

    it "does not replace the quantity of a parameter that ends in quantity", ->
      subject = new CartQuantityReplacer("http://www.nucore.org?not_quantity=16", 13)
      expect(subject.toString()).toEqual("http://www.nucore.org?not_quantity=16")

    it "replaces only the quantity that is exactly quantity", ->
      subject = new CartQuantityReplacer("http://www.nucore.org?not_quantity=16&quantity=17", 13)
      expect(subject.toString()).toEqual("http://www.nucore.org?not_quantity=16&quantity=13")

    it "replaces the quantity if it is not the last item", ->
      subject = new CartQuantityReplacer("http://www.nucore.org?quantity=16&something=17", 13)
      expect(subject.toString()).toEqual("http://www.nucore.org?quantity=13&something=17")
