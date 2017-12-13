# How to use the factories

NUcore has been upgraded to Factory Girl 3.X.

Since the upgrade from Factory Girl 1, we've set up a new series of factories for use.

## Facilities

`FactoryBot.create :setup_facility`
Creates a facility and all the necessary accounts and price groups to begin using.

## Products

### Items and Services

`FactoryBot.create :setup_item` and `FactoryBot.create :setup_service` will create all the necessary dependencies including the facility.

For putting multiple products on a facility, use:

    facility = FactoryBot.create :facility
    item1 = FactoryBot.create :setup_item, facility: facility
    item2 = FactoryBot.create :setup_item, facility: facility

### Instruments

`FactoryBot.create :setup_instrument`

#### Shared schedules

    schedule = FactoryBot.create :schedule # Will create the facility if not specified
    instrument1 = FactoryBot.create :setup_instrument, schedule: schedule
    instrument2 = FactoryBot.create :setup_instrument, schedule: schedule

## Orders

`FactoryBot.create :setup_order` will setup an order including accounts and users if not specified. It will also create an order detail if you specify a product.

    item1 = FactoryBot.create :setup_item
    order = FactoryBot.create :setup_order, product: item1 # Facility is taken from the product
    order.order_details.first # Contains an order detail of item1 with quantity 1

## Reservations

This will create a reservation, a new instrument on a new facility, with a new order. The order is not purchased.

    reservation = FactoryBot.create :setup_reservation

This will allow you to place a reservation on an already existing order detail:

    instrument = FactoryBot.create :setup_instrument
    order = FactoryBot.create :setup_order, product: instrument
    reservation = FactoryBot.create :setup_reservation, order_detail: order.order_details.first

For the ultimate in setup, you can create a purchased reservation. This alone will create all the dependencies you need.

    reservation = FactoryBot.create :purchased_reservation

If you want to specify the dependencies, you'll need to create them first and pass them in.

    instrument = FactoryBot.create :setup_instrument
    reservation1 = FactoryBot.create :purchased_reservation, product: instrument
	# Need to specify :reserve_start_at and :reserve_end_at so as not to
	# conflict with reservation1
    reservation2 = FactoryBot.create :purchased_reservation, product: instrument, reserve_start_at: reservation1.reserve_end_at, reserve_end_at: reservation1.reserve_end_at + 1.hour


