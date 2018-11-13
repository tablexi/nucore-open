# NUcore User Roles

## Jargon Explained

  - "facility"

    At some schools, this may be refered to as a "resource", "shared resource",
    or "core facility". Some user roles include the term "facility"
    such as "Facility Director" or "Facility Staff", which means they are
    specific to a specific facility.

  - "cross-facility context"

    Most NUcore functions exist in the context of a single facility, such as
    the Core Genomics Facility. But some functions may apply across all
    facilities, using the special facility name "ALL". This may be accessed by
    some of the global roles.

  - "account"

    A payment source which can be used to purchase things in NUcore. Examples include
    chart strings and purchase orders.

## Facility Operator Roles

  - Facility Staff
    * May view, but not edit administrative details about products
    * May view and update details about orders, except problem or disputed orders
    * May view instrument schedule rules but not edit or remove them
    * May view, but not change, product pricing rules
    * May add, edit, view, and remove administrative reservations for instruments
    * May view the list of product documentation files
    * May view administrative details for facility users, but not change them
    * May view orders and reservations for facility users
    * May place orders on behalf of other users
    * May grant or deny permission to use instruments
    * May view the list of accessories for a product

  - Facility Senior Staff
    * Has all the privileges of Facility Staff
    * May add or remove product accessories
    * May view product reports
    * May add, edit, and remove instrument schedule rules and scheduling groups
    * May upload and remove product documentation files

  - Facility Director
    * Has all the privileges of Facility Senior Staff
    * May manage details about the facility (name, description, contact info, etc.)
    * Has access to problem and disputed orders
    * Has access to and may manage billing to:
      - View and manage orders, including disputed orders
      - Reassign the accounts associated with orders
      - Create and manage journals
    * May edit administrative details about products
    * May bulk-import orders
    * May create new users and assign user roles
    * May add, edit and remove price groups, and add and remove a price group's users and accounts
      - An exception is that no changes to the base and external rate price groups, are allowed
      - No changes to the Cancer Center price group, aside from user membership, are allowed

  - Facility Administrator
    * Has the same privileges of Facility Directors

## Account Roles

  - Owner
    * This is usually the PI (Primary Investigator)
    * May purchase reservations, items, and services using their accounts
    * May add/remove business administrators and purchasers from their accounts
    * May view all transactions placed on their accounts regardless of who did the
      ordering.
    * May dispute charges placed on their accounts
    * Each account can have one and only one owner

  - Business Administrator
    * Has all of the same privaleges as the Owner
    * An account may have as many BAs as they would like

  - Purchaser
    * May purchase reservations, items, and services using their accounts

## Global Roles
  - Administrator
    * Virtually equivalent to being a Facility Administrator for all facilities
    * May suspend/activate accounts
    * May suspend/activate users
    * Has no restrictions except in some cross-facility contexts
      - They may not manage billing cross-facility (as Billing Administrators may do)

  - Billing Administrator
    * This role can manage billing in a cross-facility context where a user may:
      - View and manage orders, including disputed orders
      - Create and manage journals
    * The Billing Administrator role has some incompatibilities with other user roles, and
      if used, should be assigned to a dedicated user login

  - Account Manager
    * This role manages accounts and users in a cross-facility context
    * May add or remove users to virtually any account
    * May suspend/activate accounts
    * May provision new users
    * The Account Manager role has some incompatibilities with the Administrator role
