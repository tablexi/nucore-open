# Instrument Pricing

Instruments are charged at a per-minute rate.

## Charge for

### Reservation

Users are charged for the length of their reservation.

_Example_

Reservation 1-2pm

Result: User will always be charged 60 minutes, no matter the actual usage.

### Usage

Users are charged for the length of time they actually used the instrument.

This should be used in conjunction with either "Timer without relay" or "Timer with relay"
control mechanism set on the Instrument detail edit screen.

_Examples_

Reservation 1-2pm

Usage: 1:15-1:45pm
Result: User is charged for 30 minutes

Usage: 1:00-2:15pm
Result: User is charged for 75 minutes

Usage: 1:15-2:15pm
Result: User is charged for 60 minutes

### Overage

Users are charged for the length of their reservation plus any additional time spent
using the instrument after the end of the reservation.

This should be used in conjunction with either "Timer without relay" or "Timer with relay"
control mechanism set on the Instrument detail edit screen.

_Examples_

Reservation 1-2pm

Usage: 1:15-1:45pm
Result: User is charged for 60 minutes (the reservation length)

Usage: 1:00-2:15pm
Result: User is charged for 75 minutes (reservation plus 15 minutes of overage)

Usage: 1:15-2:15pm
Result: User is charged for 75 minutes (reservation plus 15 minutes of overage)
