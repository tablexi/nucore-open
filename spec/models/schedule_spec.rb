require 'spec_helper'

describe Schedule do
  let(:schedule) { FactoryGirl.create(:schedule) }
  let(:first_reservation_time) { Time.zone.parse("#{Date.today.to_s} 10:00:00") + 1.day }
  
  context 'single instrument on schedule' do
    let(:instrument) { FactoryGirl.create(:setup_instrument) }
    
    it 'should have a schedule' do
      instrument.schedule.should be
    end

    it 'should be the only product on the schedule' do
      instrument.schedule.products.should == [instrument]
    end

    context 'with a reservation placed' do
      let!(:reservation) do
        FactoryGirl.create(:purchased_reservation, 
                              :product => instrument,
                              :reserve_start_at => first_reservation_time,
                              :reserve_end_at => first_reservation_time + 1.hour)
      end

      it 'should not allow a second reservation that overlaps' do
        reservation2 = FactoryGirl.build(:setup_reservation,
                                            :product => instrument,
                                            :reserve_start_at => first_reservation_time + 30.minutes,
                                            :reserve_end_at => first_reservation_time + 1.hour + 30.minutes
                                            )
        reservation2.should_not be_valid
      end

      it "should allow a second reservation that doesn't overlap" do
        reservation2 = FactoryGirl.build(:setup_reservation,
                                            :product => instrument,
                                            :reserve_start_at => first_reservation_time + 1.hour,
                                            :reserve_end_at => first_reservation_time + 2.hours
                                            )
        reservation2.should be_valid
      end
    end
  end

  context 'two instruments on a schedule' do
    let(:instruments) { FactoryGirl.create_list(:setup_instrument, 2, :schedule => schedule) }

    context 'with a reservation placed' do
      let!(:reservation) do
        FactoryGirl.create(:purchased_reservation, 
                              :product => instruments[0],
                              :reserve_start_at => first_reservation_time,
                              :reserve_end_at => first_reservation_time + 1.hour)
      end

      it 'should not allow a second reservation that overlaps on the other instrument' do
        reservation2 = FactoryGirl.build(:setup_reservation,
                                            :product => instruments[1],
                                            :reserve_start_at => first_reservation_time + 30.minutes,
                                            :reserve_end_at => first_reservation_time + 1.hour + 30.minutes
                                            )
        reservation2.should_not be_valid
      end

      context 'a second reservation successfully placed' do
        let!(:reservation2) do
          FactoryGirl.create(:purchased_reservation, 
                              :product => instruments[1],
                              :reserve_start_at => first_reservation_time + 1.hour,
                              :reserve_end_at => first_reservation_time + 2.hours)
        end

        it 'should have the reservations under the individual instruments' do
          instruments[0].reservations.should == [reservation]
          instruments[1].reservations.should == [reservation2]
        end

        it 'should have both reservations under the schedule' do
          schedule.reservations.should == [reservation, reservation2]
        end

        it 'should be able to access the schedule reservations through the instrument' do
          instruments[0].schedule_reservations.should == [reservation, reservation2]
        end
      end
    end
  end

  describe 'active scope' do
    let(:facility) { FactoryGirl.create(:setup_facility) }
    let!(:instrument) { FactoryGirl.create(:setup_instrument, :facility => facility) }
    let!(:archived_instrument) { FactoryGirl.create(:setup_instrument, :facility => facility, :is_archived => true) }

    it 'should include non-archived schedule' do
      Schedule.active.should include instrument.schedule
    end

    it 'should not include the archived schedule' do
      Schedule.active.should_not include archived_instrument.schedule
    end
  end


end
