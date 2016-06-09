# How to use the factories

NUcore has been upgraded to Factory Girl 3.X.

Since the upgrade from Factory Girl 1, we've set up a new series of factories for use.

## Facilities

`FactoryGirl.create :setup_facility`
Creates a facility and all the necessary accounts and price groups to begin using.

## Products

### Items and Services

`FactoryGirl.create :setup_item` and `FactoryGirl.create :setup_service` will create all the necessary dependencies including the facility.

For putting multiple products on a facility, use:

    facility = FactoryGirl.create :facility
    item1 = FactoryGirl.create :setup_item, facility: facility
    item2 = FactoryGirl.create :setup_item, facility: facility

### Instruments

`FactoryGirl.create :setup_instrument`

#### Shared schedules

    schedule = FactoryGirl.create :schedule # Will create the facility if not specified
    instrument1 = FactoryGirl.create :setup_instrument, schedule: schedule
    instrument2 = FactoryGirl.create :setup_instrument, schedule: schedule

## Orders

`FactoryGirl.create :setup_order` will setup an order including accounts and users if not specified. It will also create an order detail if you specify a product.

    item1 = FactoryGirl.create :setup_item
    order = FactoryGirl.create :setup_order, product: item1 # Facility is taken from the product
    order.order_details.first # Contains an order detail of item1 with quantity 1

## Reservations

This will create a reservation, a new instrument on a new facility, with a new order. The order is not purchased.

    reservation = FactoryGirl.create :setup_reservation

This will allow you to place a reservation on an already existing order detail:

    instrument = FactoryGirl.create :setup_instrument
    order = FactoryGirl.create :setup_order, product: instrument
    reservation = FactoryGirl.create :setup_reservation, order_detail: order.order_details.first

For the ultimate in setup, you can create a purchased reservation. This alone will create all the dependencies you need.

    reservation = FactoryGirl.create :purchased_reservation

If you want to specify the dependencies, you'll need to create them first and pass them in.

    instrument = FactoryGirl.create :setup_instrument
    reservation1 = FactoryGirl.create :purchased_reservation, product: instrument
	# Need to specify :reserve_start_at and :reserve_end_at so as not to
	# conflict with reservation1
    reservation2 = FactoryGirl.create :purchased_reservation, product: instrument, reserve_start_at: reservation1.reserve_end_at, reserve_end_at: reservation1.reserve_end_at + 1.hour


