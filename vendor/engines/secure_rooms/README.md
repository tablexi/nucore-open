# SecureRooms

The SecureRooms engine adds a product type supporting an access-restricted,
bill-by-time room.

## Installation

Make sure the `gem "secure_rooms", path: "vendor/engines/secure_rooms"`
line is enabled in `Gemfile`.

## SecureRoom API
The door security hardware communicates through an API with the following endpoints:

#### Cardholder Scans at a Room Entrance

* **Method/URL**
  `POST /secure_rooms_api/scan`

* **Data Params**

  * `card_id=[integer]`
  * `controller_id=[integer]`
  * `reader_id=[integer]`
  * `some_sort_of_account_id`

* **Current Responses:**

  There are three expected types of response from a properly formatted request. Currently only one is implemented:

  **Access Denied:** The cardholder is not currently allowed to access the SecureRoom, and they are rejected.

  * **Code:** 403 Forbidden
  * **Response:**

      ```
      { response: "deny",
        reason:   "I only know how to deny right now." }
      ```

  In addition, sending identifiers that do not map to existing records will generate a not found:

  **Not Found:** One of the input identifiers does not match an existing record.

  * **Code:** 404 Not Found
  * **Response:**

      ```
      { response: "deny",
        reason:   <Error Message stating missing record> }
      ```

* **Planned Responses:**

  **Access Granted Immediately:** We can infer the cardholder's payment method, so they are cleared immediately.

  * **Code:** 200 OK
  * **Body:**

      ```
      { response: "grant" }
      ```

  **Must Select Account:** The cardholder has multiple payment methods and must select which they would like to use.

  * **Code:** 300 Multiple Choices
  * **Response:**

      ```
      { response:  "select_account",
        tablet_id: <integer id>,
        accounts:  [<list of account data TBD>] }
      ```
