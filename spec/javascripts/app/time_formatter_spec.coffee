describe "TimeFormatter", ->

  describe 'fromString', ->
    describe 'date parsing', ->
      beforeEach ->
        @formatter = new TimeFormatter.fromString('4/17/2015', '3', '15', 'AM')

      it 'has the correct year', ->
        expect(@formatter.year()).toEqual(2015)

      it 'has the correct month', ->
        expect(@formatter.month()).toEqual(4)
        expect(@formatter.toString()).toContain('Apr')

      it 'has the correct day', ->
        expect(@formatter.day()).toEqual(17)

      it 'has the correctly formatted date', ->
        expect(@formatter.dateString()).toEqual('4/17/2015')

    describe 'time parsing', ->
      it 'sets the right time for an AM', ->
        formatter = new TimeFormatter.fromString('6/13/2015', '3', '15', 'AM')
        expect(formatter.hour24()).toEqual(3)
        expect(formatter.minute()).toEqual(15)

      it 'sets the right time for PM', ->
        formatter = new TimeFormatter.fromString('6/13/2015', '3', '15', 'PM')
        expect(formatter.hour24()).toEqual(15)
        expect(formatter.minute()).toEqual(15)

      it 'sets the right hour for midnight', ->
        formatter = new TimeFormatter.fromString('6/13/2015', '12', '00', 'AM')
        expect(formatter.hour24()).toEqual(0)

      it 'sets the right hour for noon', ->
        formatter = new TimeFormatter.fromString('6/13/2015', '12', '00', 'PM')
        expect(formatter.hour24()).toEqual(12)

  describe 'from a Date', ->
    it 'has the right month', ->
      date = new Date(2015, 3, 12, 3, 15)
      formatter = new TimeFormatter(date)
      expect(formatter.month()).toEqual(4)
      expect(date.toString()).toContain('Apr')
      expect(formatter.toString()).toContain('Apr')

    it 'gives the right formatted date', ->
      date = new Date(2015, 3, 12, 3, 15)
      formatter = new TimeFormatter(date)
      expect(formatter.dateString()).toEqual('4/12/2015')

    it 'gives the right thing for an AM', ->
      date = new Date(2015, 3, 12, 3, 15)
      formatter = new TimeFormatter(date)
      expect(formatter.hour12()).toEqual(3)
      expect(formatter.meridian()).toEqual('AM')

    it 'gives the right thing for a PM', ->
      date = new Date(2015, 3, 12, 15, 15)
      formatter = new TimeFormatter(date)
      expect(formatter.hour12()).toEqual(3)
      expect(formatter.meridian()).toEqual('PM')

    it 'gives the right thing for midnight', ->
      date = new Date(2015, 3, 12, 0, 15)
      formatter = new TimeFormatter(date)
      expect(formatter.hour12()).toEqual(12)
      expect(formatter.meridian()).toEqual('AM')

    it 'gives the right thing for noon', ->
      date = new Date(2015, 3, 12, 12, 15)
      formatter = new TimeFormatter(date)
      expect(formatter.hour12()).toEqual(12)
      expect(formatter.meridian()).toEqual('PM')
