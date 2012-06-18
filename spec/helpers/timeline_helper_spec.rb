require 'spec_helper'

describe TimelineHelper do
  before :each do
    @display_date = Time.zone.now
  end
  
  context 'datetime_left_position' do
    it 'should return 0 if the start time is yesterday' do
      datetime_left_position(@display_date, Time.zone.now.beginning_of_day - 1.hour).should == '0px'
    end    
    it 'should return 60 for 8am' do
      eight_pm = Time.zone.now.beginning_of_day.change({:hour => 8})
      datetime_left_position(@display_date, eight_pm).should == "#{(480 * TimelineHelper::MINUTE_TO_PIXEL_RATIO).floor}px"
    end

  end

  context 'datetime_width' do
    before :each do
      @reservation = Reservation.new(:reserve_start_at => Time.zone.now.change({:hour => 8, :min =>0}),
                                     :reserve_end_at => Time.zone.now.change({:hour => 10, :min => 0}))
      @reservation_spans_yesterday = Reservation.new(:reserve_start_at => (Time.zone.now - 1.day).change({:hour => 23, :min =>0}),
                                     :reserve_end_at => Time.zone.now.change({:hour => 2, :min => 0}))
      @reservation_spans_tomorrow = Reservation.new(:reserve_start_at => Time.zone.now.change({:hour => 23, :min =>0}),
                                     :reserve_end_at => (Time.zone.now + 1.day).change({:hour => 3, :min => 0}))
    end
    it 'should return a full width if start and end are in the same day' do
      width = (120 * TimelineHelper::MINUTE_TO_PIXEL_RATIO).floor
      @reservation.duration_mins.should == 120
      datetime_width(@display_date, @reservation.reserve_start_at, @reservation.reserve_end_at).should == "#{width}px"
    end
    
    it 'should be shorter if it starts before midnight' do
      @reservation_spans_yesterday.duration_mins.should == 180
      width = (120 * TimelineHelper::MINUTE_TO_PIXEL_RATIO).floor
      datetime_width(@display_date, @reservation_spans_yesterday.reserve_start_at, @reservation_spans_yesterday.reserve_end_at).should == "#{width}px"
    end
    
    it 'should be shorter if it ends after midnight' do
      @reservation_spans_tomorrow.duration_mins.should == 240
      width = (60 * TimelineHelper::MINUTE_TO_PIXEL_RATIO).floor
      datetime_width(@display_date, @reservation_spans_tomorrow.reserve_start_at, @reservation_spans_tomorrow.reserve_end_at).should == "#{width}px"
    end
  end

  context 'spans_midnight_class' do
    before :each do
      @reservation = Reservation.new(:reserve_start_at => Time.zone.now.change({:hour => 8, :min =>0}),
                                     :reserve_end_at => Time.zone.now.change({:hour => 10, :min => 0}))
      @reservation_spans_yesterday = Reservation.new(:reserve_start_at => (Time.zone.now - 1.day).change({:hour => 23, :min =>0}),
                                     :reserve_end_at => Time.zone.now.change({:hour => 2, :min => 0}))
      @reservation_spans_tomorrow = Reservation.new(:reserve_start_at => Time.zone.now.change({:hour => 23, :min =>0}),
                                     :reserve_end_at => (Time.zone.now + 1.day).change({:hour => 3, :min => 0}))
    end
    it 'should have nothing for a normal reservation' do
      spans_midnight_class(@reservation.reserve_start_at, @reservation.reserve_end_at).should be_nil
    end

    it 'should return the right class for one that spans yesterday' do
      spans_midnight_class(@reservation_spans_yesterday.reserve_start_at, @reservation_spans_yesterday.reserve_end_at).should == 'spans_into_yesterday'
    end
    it 'should return the right class for one that spans tomorrow' do
      spans_midnight_class(@reservation_spans_tomorrow.reserve_start_at, @reservation_spans_tomorrow.reserve_end_at).should == 'spans_into_tomorrow'
    end
  end
  
end