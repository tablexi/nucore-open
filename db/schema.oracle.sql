------------------------------------------------------------------------------
-- Common
------------------------------------------------------------------------------

CREATE TABLE schema_migrations (
version             VARCHAR(255) NOT NULL,
UNIQUE (version)
);
INSERT INTO schema_migrations (version) VALUES ('20100526190311');


------------------------------------------------------------------------------
-- Facilities
------------------------------------------------------------------------------

CREATE SEQUENCE facilities_seq;
CREATE TABLE facilities (
id                  INTEGER        NOT NULL PRIMARY KEY,
name                VARCHAR2(200)  NOT NULL,
abbreviation        VARCHAR2(50)   NOT NULL,
url_name            VARCHAR2(50)    NOT NULL,
description         CLOB,
pers_affiliate_id   INTEGER,
is_active           NUMBER(1)      NOT NULL,
created_at          DATE           NOT NULL,
updated_at          DATE           NOT NULL,
accepts_cc          NUMBER(1)      NOT NULL,
accepts_po          NUMBER(1)      NOT NULL,
short_description   CLOB           NOT NULL,
UNIQUE (name),
UNIQUE (abbreviation),
UNIQUE (url_name)
-- TODO: add common addresses or just add them directly to this model
-- address_id          INTEGER        NOT NULL,
-- FOREIGN KEY (address_id) REFERENCES addresses (id)
);


------------------------------------------------------------------------------
-- Accounts
------------------------------------------------------------------------------

CREATE SEQUENCE accounts_seq;
CREATE TABLE accounts (
-- common fields
id                  INTEGER        NOT NULL PRIMARY KEY,
type                VARCHAR2(50)   NOT NULL,
account_number      VARCHAR2(50)   NOT NULL,
description         VARCHAR2(200)  NOT NULL,
expires_at          DATE           NOT NULL,
-- credit_card fields
name_on_card        VARCHAR2(200),
credit_card_number_encrypted  VARCHAR2(200),
expiration_month    INTEGER,
expiration_year     INTEGER,
-- auditing fields
created_at          DATE           NOT NULL,
created_by          INTEGER        NOT NULL,
updated_at          DATE,
updated_by          INTEGER,
suspended_at        DATE
);

CREATE SEQUENCE account_users_seq;
CREATE TABLE account_users (
id                  INTEGER        NOT NULL PRIMARY KEY,
account_id          INTEGER        NOT NULL,
user_id             INTEGER        NOT NULL,
user_role           VARCHAR2(50)   NOT NULL,
created_at          DATE           NOT NULL,
created_by          INTEGER        NOT NULL,            
deleted_at          DATE,
deleted_by          INTERGER,
FOREIGN KEY (account_id) REFERENCES accounts (id)
);


CREATE SEQUENCE facility_accounts_seq;
CREATE TABLE facility_accounts (
id              INTEGER         NOT NULL PRIMARY KEY,
facility_id     INTEGER         NOT NULL,
account_number  VARCHAR2(50)    NOT NULL,
is_active       NUMBER(1)       NOT NULL,
created_by      INTEGER         NOT NULL,
created_at      DATE            NOT NULL,
revenue_account INTEGER         NOT NULL
);


CREATE SEQUENCE budgeted_chart_strings_seq;
CREATE TABLE budgeted_chart_strings (
id              INTEGER         NOT NULL PRIMARY KEY,
fund            VARCHAR2(20)    NOT NULL,
dept            VARCHAR2(20)    NOT NULL,
project         VARCHAR2(20),
activity        VARCHAR2(20),
account         VARCHAR2(20),
starts_at       DATE            NOT NULL,
expires_at      DATE            NOT NULL
);


------------------------------------------------------------------------------
-- Products
------------------------------------------------------------------------------

CREATE SEQUENCE order_statuses_seq;
CREATE TABLE order_statuses (
id                  INTEGER        NOT NULL PRIMARY KEY,
name                VARCHAR2(50)   NOT NULL,
facility_id         INTEGER,
parent_id           INTEGER,
lft                 INTEGER,
rgt                 INTEGER,
UNIQUE(facility_id, parent_id, name)
);


CREATE SEQUENCE products_seq;
CREATE TABLE products (
id                       INTEGER        NOT NULL PRIMARY KEY,
type                     VARCHAR2(50)   NOT NULL,
facility_id              INTEGER        NOT NULL,
name                     VARCHAR2(200)  NOT NULL,
url_name                 VARCHAR2(50)   NOT NULL,
description              CLOB,
-- requires approval to order
requires_approval        NUMBER(1)      NOT NULL,
-- default to "New", could be "Waiting for Sample"
initial_order_status_id  INTEGER        NOT NULL,
-- may not be ordered if archived
is_archived              NUMBER(1)      NOT NULL,
-- only orderable through bundle if hidden
is_hidden                NUMBER(1)      NOT NULL,
created_at               DATE           NOT NULL,
updated_at               DATE           NOT NULL,
--instrument properties
relay_ip                 VARCHAR2(15),
relay_port               INTEGER,
relay_username           VARCHAR2(50),
relay_password           VARCHAR2(50),
auto_logout              NUMBER(1),
min_reserve_mins         INTEGER,
max_reserve_mins         INTEGER,
-- min number of hours prior to reservation to cancel to avoid charges
min_cancel_hours          INTEGER,
facility_account_id      INTEGER        NOT NULL,
account                  INTEGER        NOT NULL,
UNIQUE(relay_ip, relay_port),
FOREIGN KEY (facility_id)   REFERENCES facilities  (id)
);


CREATE SEQUENCE schedule_rules_seq;
CREATE TABLE schedule_rules (
id                    INTEGER        NOT NULL PRIMARY KEY,
instrument_id         INTEGER        NOT NULL,
discount_percent      DECIMAL(10,2)  DEFAULT 0 NOT NULL,
-- weekends, nights might have a % discount
start_hour            INTEGER        NOT NULL,
start_min             INTEGER        NOT NULL,
-- hour:min during the day to start
end_hour              INTEGER        NOT NULL,
end_min               INTEGER        NOT NULL,
-- hour:min during the day to end
duration_mins         INTEGER        NOT NULL,
-- duration_mins > 0
on_sun                NUMBER(1)      NOT NULL,
on_mon                NUMBER(1)      NOT NULL,
on_tue                NUMBER(1)      NOT NULL,
on_wed                NUMBER(1)      NOT NULL,
on_thu                NUMBER(1)      NOT NULL,
on_fri                NUMBER(1)      NOT NULL,
on_sat                NUMBER(1)      NOT NULL,
FOREIGN KEY (instrument_id) REFERENCES products (id)
);

-- products may require users to be authorized
CREATE SEQUENCE product_users_seq;
CREATE TABLE product_users (
id                  INTEGER        NOT NULL PRIMARY KEY,
product_id          INTEGER        NOT NULL,
user_id             INTEGER        NOT NULL,
approved_by         INTEGER,
approved_at         DATE,
FOREIGN KEY (product_id) REFERENCES products (id)
);


CREATE SEQUENCE instrument_statuses_seq;
CREATE TABLE instrument_statuses (
id                  INTEGER     NOT NULL PRIMARY KEY,
instrument_id       INTEGER     NOT NULL,
is_on               NUMBER(1)   NOT NULL,
created_at          DATE        NOT NULL,
FOREIGN KEY (instrument_id) REFERENCES products (id)
);


-- Bundled products hierarchy
CREATE SEQUENCE bundle_products_seq;
CREATE TABLE bundle_products (
id                  INTEGER        NOT NULL PRIMARY KEY,
bundle_product_id   INTEGER        NOT NULL,
product_id          INTEGER        NOT NULL,
quantity            INTEGER        NOT NULL,
FOREIGN KEY (bundle_product_id) REFERENCES products (id),
FOREIGN KEY (product_id)        REFERENCES products (id)
);


------------------------------------------------------------------------------
-- Pricing Policies
------------------------------------------------------------------------------

CREATE SEQUENCE price_groups_seq;
CREATE TABLE price_groups (
id                  INTEGER        NOT NULL PRIMARY KEY,
facility_id         INTEGER,
name                VARCHAR2(50)   NOT NULL,
display_order       INTEGER        NOT NULL,
is_internal         NUMBER(1)      NOT NULL,
UNIQUE(facility_id, name),
FOREIGN KEY (facility_id)   REFERENCES facilities  (id)
);


-- STI for user_ and account_
CREATE SEQUENCE price_group_members_seq;
CREATE TABLE price_group_members (
id                  INTEGER        NOT NULL PRIMARY KEY,
type                VARCHAR2(50)   NOT NULL,
price_group_id      INTEGER        NOT NULL,
user_id             INTEGER,
account_id          INTEGER,
FOREIGN KEY (price_group_id) REFERENCES price_groups (id)
-- removed due to STI: FOREIGN KEY (user_id)        REFERENCES users (id)
-- removed due to STI: FOREIGN KEY (account_id)     REFERENCES accounts (id)
);


CREATE SEQUENCE price_policies_seq;
CREATE TABLE price_policies (
id                  INTEGER        NOT NULL PRIMARY KEY,
type                VARCHAR2(50)   NOT NULL,
instrument_id       INTEGER,
service_id          INTEGER,
item_id             INTEGER,
price_group_id      INTEGER        NOT NULL,
start_date          DATE           NOT NULL,
-- items and services
unit_cost           DECIMAL(10,2),
unit_subsidy        DECIMAL(10,2),
-- instruments
usage_rate          DECIMAL(10,2),
usage_mins          INTEGER,
reservation_rate    DECIMAL(10,2),
reservation_mins    INTEGER,
overage_rate        DECIMAL(10,2),
overage_mins        INTEGER,
minimum_cost        DECIMAL(10,2),
cancellation_cost   DECIMAL(10,2),
reservation_window  INTEGER,
usage_subsidy       DECIMAL(10,2),
reservation_subsidy DECIMAL(10,2),
overage_subsidy     DECIMAL(10,2),
restrict_purchase   NUMBER(1)      NOT NULL,
FOREIGN KEY (price_group_id) REFERENCES price_groups (id)
);


------------------------------------------------------------------------------
-- Billing
------------------------------------------------------------------------------


CREATE SEQUENCE statements_seq;
CREATE TABLE statements (
id           INTEGER     NOT NULL PRIMARY KEY,
facility_id  INTEGER     NOT NULL,
created_by   INTEGER     NOT NULL,
created_at   DATE        NOT NULL,
invoice_date DATE        NOT NULL
);


CREATE SEQUENCE journals_seq;
CREATE TABLE journals (
id                INTEGER         NOT NULL PRIMARY KEY,
facility_id       INTEGER         NOT NULL,
reference         VARCHAR2(50),
description       VARCHAR2(200),
is_successful     NUMBER(1),
created_by        INTEGER         NOT NULL,
created_at        DATE            NOT NULL,
updated_by        INTEGER,
updated_at        DATE,
file_file_name    VARCHAR(255),
file_content_type VARCHAR(255),
file_file_size    INTEGER,
file_updated_at   DATE,
FOREIGN KEY (facility_id) REFERENCES facilities (id)
);


CREATE SEQUENCE journal_rows_seq;
CREATE TABLE journal_rows (
id                      INTEGER        NOT NULL PRIMARY KEY,
fund                    INTEGER        NOT NULL,
dept                    INTEGER        NOT NULL,
project                 INTEGER        NOT NULL,
activity                INTEGER,
program                 INTEGER,
account                 INTEGER        NOT NULL,
amount                  DECIMAL(10,2)  NOT NULL,
description             VARCHAR2(200),
reference               VARCHAR2(50),
account_transaction_id INTEGER,
FOREIGN KEY (order_detail_id) REFERENCES facilities (id),
FOREIGN KEY (account_transaction_id) REFERENCES account_transactions(id)
);


CREATE SEQUENCE account_transactions_seq
CREATE TABLE account_transactions (
id                  INTEGER         NOT NULL PRIMARY KEY,
account_id          INTEGER         NOT NULL,
facility_id         INTEGER         NOT NULL,
description         VARCHAR2(200)   NOT NULL,
transaction_amount  DECIMAL(10,2)   NOT NULL,
type                VARCHAR2(50)    NOT NULL,
finalized_at        DATE,
order_detail_id     INTEGER,
created_by          INTEGER         NOT NULL,
created_at          DATE            NOT NULL,
is_in_dispute       NUMBER(1)       NOT NULL,
statement_id        INTEGER,
reference           VARCHAR2(50)
);


------------------------------------------------------------------------------
-- Orders
------------------------------------------------------------------------------

CREATE SEQUENCE orders_seq;
CREATE TABLE orders (
id                  INTEGER        NOT NULL PRIMARY KEY,
facility_id         INTEGER,
-- the customer cc_pers, t_personnel.personnel_id
user_id             INTEGER        NOT NULL,
-- when creating an order on behalf of another user this will differ from user_id
created_by          INTEGER        NOT NULL,
account_id          INTEGER,
-- time of cart creation
created_at          DATE           NOT NULL,
-- time of last update
updated_at          DATE           NOT NULL,
-- time or cart->order conversion
ordered_at          DATE,
state               VARCHAR2(200),
FOREIGN KEY (account_id)  REFERENCES accounts (id),
FOREIGN KEY (facility_id) REFERENCES facilities (id)
);


CREATE SEQUENCE reservations_seq;
CREATE TABLE reservations (
id                     INTEGER        NOT NULL PRIMARY KEY,
-- reservation doesn't necessarily tie to an order_detail
order_detail_id        INTEGER,
instrument_id          INTEGER        NOT NULL,
reserve_start_at       DATE           NOT NULL,
reserve_end_at         DATE           NOT NULL,
actual_start_at        DATE,
actual_end_at          DATE,
canceled_at            DATE,
canceled_by            INTEGER,
canceled_reason        VARCHAR2(50),
FOREIGN KEY (order_detail_id)  REFERENCES order_details (id),
FOREIGN KEY (instrument_id)  REFERENCES products (id)
);

CREATE SEQUENCE order_details_seq;
CREATE TABLE order_details (
id                      INTEGER        NOT NULL PRIMARY KEY,
order_id                INTEGER        NOT NULL,
-- the product being ordered
product_id              INTEGER        NOT NULL,
-- the bundle if it is in a bundle
-- bundle_id            INTEGER,
-- quantity, reservation quantity is 1
quantity                INTEGER        NOT NULL,
-- price policy (price policy is versioned by date)
price_policy_id         INTEGER,
estimated_cost          DECIMAL(10,2),
estimated_subsidy       DECIMAL(10,2),
actual_cost             DECIMAL(10,2),
actual_subsidy          DECIMAL(10,2),
-- the staff user who is working on this part of the order
assigned_user_id        INTEGER,
account_id              INTEGER,
dispute_at              DATE,
dispute_reason          VARCHAR2(200),
dispute_resolved_at     DATE,
dispute_resolved_reason VARCHAR2(200),
dispute_resolved_credit DECIMAL(10,2),
created_at              DATE,
updated_at              DATE,
order_status_id         INTEGER        NOT NULL,
state                   VARCHAR2(50),
bundle_order_detail_id  INTEGER,
FOREIGN KEY (account_id)             REFERENCES accounts (id),
FOREIGN KEY (order_id)               REFERENCES orders   (id),
FOREIGN KEY (order_status_id)        REFERENCES order_statuses (id),
FOREIGN KEY (product_id)             REFERENCES products (id),
FOREIGN KEY (price_policy_id)        REFERENCES price_policies (id)
FOREIGN KEY (bundle_order_detail_id) REFERENCES order_details (id)
);

CREATE SEQUENCE versions_seq;
CREATE TABLE versions (
id              INTEGER     NOT NULL PRIMARY KEY,
versioned_id    INTEGER,
versioned_type  VARCHAR2,
user_id         INTEGER,
user_type       VARCHAR2,
user_name       VARCHAR2,
data_changes    CLOB,
number          INTEGER,
tag             VARCHAR2,
created_at      DATE,
updated_at      DATE
);


------------------------------------------------------------------------------
-- Files
------------------------------------------------------------------------------
CREATE SEQUENCE file_uploads_seq;
CREATE TABLE file_uploads (
id                  INTEGER       NOT NULL PRIMARY KEY,
order_detail_id     INTEGER,
product_id          INTEGER,
name                VARCHAR2(200) NOT NULL,
file_type           VARCHAR2(50)  NOT NULL,
created_by          INTEGER       NOT NULL,
created_at          DATE          NOT NULL,
file_file_name      VARCHAR2(255),
file_content_type   VARCHAR2(255),
file_file_size      INTEGER,
file_updated_at     DATE,
FOREIGN KEY (order_detail_id)     REFERENCES orders   (id),
FOREIGN KEY (product_id)             REFERENCES products (id)
);


------------------------------------------------------------------------------
-- Surveys
------------------------------------------------------------------------------
CREATE SEQUENCE question_groups_seq
CREATE TABLE question_groups (
);

CREATE SEQUENCE answers_seq
CREATE TABLE answers (
);

CREATE SEQUENCE dependency_conditions_seq
CREATE TABLE dependency_conditions (
);

CREATE SEQUENCE dependencies_seq
CREATE TABLE dependencies (
);

CREATE SEQUENCE questions_seq
CREATE TABLE questions (
);

CREATE SEQUENCE response_sets_seq
CREATE TABLE response_sets (
);

CREATE SEQUENCE responses_seq
CREATE TABLE responses (
);

CREATE SEQUENCE service_surveys_seq
CREATE TABLE service_surveys (
);

CREATE SEQUENCE survey_sections_seq
CREATE TABLE survey_sections (
);

CREATE SEQUENCE surveys_seq
CREATE TABLE surveys (
);

CREATE SEQUENCE validation_conditions_seq
CREATE TABLE validation_conditions (
);

CREATE SEQUENCE validations_seq
CREATE TABLE validations (
);


