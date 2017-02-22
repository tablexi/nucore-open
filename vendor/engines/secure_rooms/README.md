# SecureRooms

The SecureRooms engine adds a product type supporting an access-restricted,
bill-by-time room.

## Installation

Make sure the `gem "secure_rooms",   "~> 0.0.1", path: "vendor/engines/secure_rooms"`
line is enabled in `Gemfile`.

## SecureRoom API
The door security hardware communicates through an API with the following endpoints:

#### Cardholder Scans at a Room Entrance

* **Method/URL**
  `POST /secure_rooms_api/scan`

* **Data Params**

  * `ard_id=[integer]`
  * `controller_id=[integer]`
  * `outside_reader_id=[integer]`

* **Success Response:**
  There are three types of response:


  **Response 1:** We can infer the cardholder's payment method, so they are cleared immediately.

  * **Code:** 200 OK
  * **Body:**

      ```
      { response: "grant" }
      ```

  **Response 2:** The cardholder has multiple payment methods and must select which they would like to use.

  * **Code:** 200 OK
  * **Response:**

      ```
      { response: "deny",
          reason:   "I only know how to deny right now." }
      ```

  **Response 3:** The cardholder is not currently allowed to access the SecureRoom, and they are rejected.

  * **Code:** 200 OK
  * **Response:**

      ```
      { response:   "select_account",
          tablet_id:  <integer id>,
          accounts:   [] }
      ```
