CREATE EXTENSION "uuid-ossp";

CREATE TYPE direction AS ENUM ('DEBIT', 'CREDIT');
CREATE TYPE ttype AS ENUM ('ORDER', 'TRANSFER', 'CONVERT');

CREATE TABLE IF NOT EXISTS account
(
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    portfolio_id UUID                           NOT NULL,
    user_id      UUID                           NOT NULL,
    currency     VARCHAR(64)                    NOT NULL,
    created_at   TIMESTAMPTZ(3)   DEFAULT NOW() NOT NULL
);

CREATE INDEX user_accounts ON account USING HASH(user_id);
CREATE INDEX idem_user_account ON account (portfolio_id, currency, user_id);

CREATE TABLE IF NOT EXISTS account_balance
(
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID                           NOT NULL REFERENCES account (id),
    balance    NUMERIC          DEFAULT 0     NOT NULL CHECK (balance >= 0),
    hold       NUMERIC          DEFAULT 0     NOT NULL CHECK (hold >= 0),
    available  NUMERIC          DEFAULT 0     NOT NULL CHECK (available >= 0),
    created_at TIMESTAMPTZ(3)   DEFAULT NOW() NOT NULL,
    request_id UUID,
    count      NUMERIC          DEFAULT 1     NOT NULL
);

CREATE INDEX account_balance_index ON account_balance USING HASH(account_id);

CREATE TABLE IF NOT EXISTS transaction
(
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id        UUID  NOT NULL REFERENCES account (id),
    receiver_id      UUID  NOT NULL REFERENCES account (id),
    request_id       UUID  NOT NULL,
    transaction_type TTYPE NOT NULL,
    created_at       TIMESTAMPTZ(3)   DEFAULT NOW()
);

CREATE INDEX sender_transactions ON transaction USING HASH(sender_id);
CREATE INDEX receiver_transactions ON transaction USING HASH(receiver_id);

CREATE TABLE IF NOT EXISTS finalized_transaction
(
    transaction_id UUID PRIMARY KEY REFERENCES transaction (id),
    completed_at   TIMESTAMPTZ(3),
    canceled_at    TIMESTAMPTZ(3),
    failed_at      TIMESTAMPTZ(3),
    request_id     UUID NOT NULL
);

CREATE TABLE IF NOT EXISTS entry
(
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id     UUID                           NOT NULL REFERENCES account (id),
    transaction_id UUID                           NOT NULL REFERENCES transaction (id),
    request_id     UUID                           NOT NULL,
    amount         NUMERIC                        NOT NULL CHECK (amount > 0),
    direction      DIRECTION                      NOT NULL,
    created_at     TIMESTAMPTZ(3)   DEFAULT NOW() NOT NULL
);

CREATE INDEX transaction_entries ON entry USING HASH(transaction_id);
CREATE INDEX request_entries ON entry USING HASH(request_id);
CREATE INDEX account_entries ON entry USING HASH(account_id);

CREATE TABLE IF NOT EXISTS hold
(
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id     UUID                           NOT NULL REFERENCES account (id),
    transaction_id UUID                           NOT NULL REFERENCES transaction (id),
    request_id     UUID                           NOT NULL,
    amount         NUMERIC                        NOT NULL CHECK (amount > 0),
    created_at     TIMESTAMPTZ(3)   DEFAULT NOW() NOT NULL
);

CREATE INDEX transaction_holds ON hold USING HASH(transaction_id);
CREATE INDEX request_holds ON hold USING HASH(request_id);
CREATE INDEX account_holds ON hold USING HASH(account_id);

CREATE TABLE IF NOT EXISTS released_hold
(
    hold_id     UUID PRIMARY KEY REFERENCES hold (id),
    released_at TIMESTAMPTZ(3) DEFAULT NOW() NOT NULL,
    request_id  UUID                         NOT NULL
);

