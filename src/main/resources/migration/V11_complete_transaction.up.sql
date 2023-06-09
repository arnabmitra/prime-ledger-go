
CREATE OR REPLACE FUNCTION complete_transaction(
    arg_transaction_id UUID,
    arg_request_id UUID
) RETURNS transaction_result
    LANGUAGE plpgsql
AS
$$
DECLARE
    temp_transaction           transaction;
    temp_finalized_transaction finalized_transaction;
    temp_hold                  hold;
    sender_account             account;
    receiver_account           account;
    sender_most_recent_balance account_balance;
    temp_hold_amount           NUMERIC;
    temp_sender_new_balance_id UUID;
    result                     transaction_result;
BEGIN
    SELECT * FROM transaction WHERE id = arg_transaction_id INTO temp_transaction;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'LGR404';
    END IF;

    --Locking
    LOCK TABLE account IN ROW EXCLUSIVE MODE;
    SELECT * FROM account WHERE id = temp_transaction.sender_id into sender_account FOR UPDATE;
    SELECT * FROM account WHERE id = temp_transaction.receiver_id into receiver_account FOR UPDATE;

    SELECT *
    FROM finalized_transaction
    WHERE transaction_id = arg_transaction_id
    INTO temp_finalized_transaction;
    IF FOUND THEN
        result.sender_balance_id = (SELECT id
                                    FROM account_balance
                                    WHERE request_id = arg_request_id
                                      AND account_id = temp_transaction.sender_id);
        result.receiver_balance_id = (SELECT id
                                      FROM account_balance
                                      WHERE request_id = arg_request_id
                                        AND account_id = temp_transaction.receiver_id);
        UPDATE account SET user_id = sender_account.user_id WHERE id = sender_account.id;
        UPDATE account SET user_id = receiver_account.user_id WHERE id = receiver_account.id;
        RETURN result;
    END IF;

    SELECT *
    FROM hold
    WHERE hold.transaction_id = arg_transaction_id
      AND hold.account_id = temp_transaction.sender_id
      AND NOT EXISTS(
            SELECT hold_id
            FROM released_hold
            WHERE released_hold.hold_id = hold.id)
    INTO temp_hold;

    IF FOUND THEN
        INSERT INTO released_hold (hold_id, request_id) VALUES (temp_hold.id, arg_request_id);

        result.hold_id = temp_hold.id;

        --Update Sender Balance
        SELECT *
        FROM get_latest_balance(
                temp_transaction.sender_id
            )
        INTO sender_most_recent_balance;

        temp_hold_amount = sender_most_recent_balance.hold - temp_hold.amount;

        INSERT INTO account_balance(account_id, request_id, balance, hold, available, count)
        VALUES (temp_transaction.sender_id, arg_request_id, sender_most_recent_balance.balance, temp_hold_amount,
                sender_most_recent_balance.balance - temp_hold_amount, sender_most_recent_balance.count + 1)
        RETURNING id INTO temp_sender_new_balance_id;

        result.sender_balance_id = temp_sender_new_balance_id;
    END IF;

    --Finalize Transaction
    INSERT INTO finalized_transaction (transaction_id, completed_at, request_id)
    VALUES (arg_transaction_id, now(), arg_request_id);

    UPDATE account SET user_id = sender_account.user_id WHERE id = sender_account.id;
    UPDATE account SET user_id = receiver_account.user_id WHERE id = receiver_account.id;

    RETURN result;
END
$$;

CREATE OR REPLACE FUNCTION fail_transaction(
    arg_transaction_id UUID,
    arg_request_id UUID
) RETURNS transaction_result
    LANGUAGE plpgsql
AS
$$
DECLARE
    temp_transaction           transaction;
    temp_finalized_transaction finalized_transaction;
    temp_hold                  hold;
    sender_account             account;
    sender_most_recent_balance account_balance;
    temp_hold_amount           NUMERIC;
    temp_sender_new_balance_id UUID;
    result                     transaction_result;
BEGIN
    SELECT * FROM transaction WHERE id = arg_transaction_id INTO temp_transaction;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'LGR404';
    END IF;

    --Locking
    LOCK TABLE account IN ROW EXCLUSIVE MODE;
    SELECT * FROM account WHERE id = temp_transaction.sender_id into sender_account FOR UPDATE;

    SELECT *
    FROM finalized_transaction
    WHERE transaction_id = arg_transaction_id
    INTO temp_finalized_transaction;
    IF FOUND THEN
        result.sender_balance_id = (SELECT id
                                    FROM account_balance
                                    WHERE request_id = arg_request_id
                                      AND account_id = temp_transaction.sender_id);
        result.receiver_balance_id = (SELECT id
                                      FROM account_balance
                                      WHERE request_id = arg_request_id
                                        AND account_id = temp_transaction.receiver_id);
        UPDATE account SET user_id = sender_account.user_id WHERE id = sender_account.id;
        RETURN result;
    END IF;

    SELECT *
    FROM hold
    WHERE hold.transaction_id = arg_transaction_id
      AND hold.account_id = temp_transaction.sender_id
      AND NOT EXISTS(
            SELECT hold_id
            FROM released_hold
            WHERE released_hold.hold_id = hold.id)
    INTO temp_hold;

    IF FOUND THEN
        INSERT INTO released_hold (hold_id, request_id) VALUES (temp_hold.id, arg_request_id);

        result.hold_id = temp_hold.id;

        --Update Sender Balance
        SELECT *
        FROM get_latest_balance(
                temp_transaction.sender_id
            )
        INTO sender_most_recent_balance;

        temp_hold_amount = sender_most_recent_balance.hold - temp_hold.amount;

        INSERT INTO account_balance(account_id, request_id, balance, hold, available, count)
        VALUES (temp_transaction.sender_id, arg_request_id, sender_most_recent_balance.balance, temp_hold_amount,
                sender_most_recent_balance.balance - temp_hold_amount, sender_most_recent_balance.count + 1)
        RETURNING id INTO temp_sender_new_balance_id;

        result.sender_balance_id = temp_sender_new_balance_id;
    END IF;

    --Finalize Transaction
    INSERT INTO finalized_transaction (transaction_id, failed_at, request_id)
    VALUES (arg_transaction_id, now(), arg_request_id);

    UPDATE account SET user_id = sender_account.user_id WHERE id = sender_account.id;

    RETURN result;
END
$$;

CREATE OR REPLACE FUNCTION cancel_transaction(
    arg_transaction_id UUID,
    arg_request_id UUID
) RETURNS transaction_result
    LANGUAGE plpgsql
AS
$$
DECLARE
    temp_transaction           transaction;
    temp_finalized_transaction finalized_transaction;
    temp_hold                  hold;
    sender_account             account;
    sender_most_recent_balance account_balance;
    temp_hold_amount           NUMERIC;
    temp_sender_new_balance_id uuid;
    result                     transaction_result;
BEGIN
    SELECT * FROM transaction WHERE id = arg_transaction_id INTO temp_transaction;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'LGR404';
    END IF;

    --Locking
    LOCK TABLE account IN ROW EXCLUSIVE MODE;
    SELECT * FROM account WHERE id = temp_transaction.sender_id into sender_account FOR UPDATE;

    SELECT *
    FROM finalized_transaction
    WHERE transaction_id = arg_transaction_id
    INTO temp_finalized_transaction;
    IF FOUND THEN
        result.sender_balance_id = (SELECT id
                                    FROM account_balance
                                    WHERE request_id = arg_request_id
                                      AND account_id = temp_transaction.sender_id);
        result.receiver_balance_id = (SELECT id
                                      FROM account_balance
                                      WHERE request_id = arg_request_id
                                        AND account_id = temp_transaction.receiver_id);
        UPDATE account SET user_id = sender_account.user_id WHERE id = sender_account.id;
        RETURN result;
    END IF;

    SELECT *
    FROM hold
    WHERE hold.transaction_id = arg_transaction_id
      AND hold.account_id = temp_transaction.sender_id
      AND NOT EXISTS(
            SELECT hold_id
            FROM released_hold
            WHERE released_hold.hold_id = hold.id)
    INTO temp_hold;

    IF FOUND THEN --Release the hold
        INSERT INTO released_hold (hold_id, request_id) VALUES (temp_hold.id, arg_request_id);

        result.hold_id = temp_hold.id;

        --Update Sender Balance
        SELECT *
        FROM get_latest_balance(
                temp_transaction.sender_id
            )
        INTO sender_most_recent_balance;

        temp_hold_amount = sender_most_recent_balance.hold - temp_hold.amount;

        INSERT INTO account_balance(account_id, request_id, balance, hold, available, count)
        VALUES (temp_transaction.sender_id, arg_request_id, sender_most_recent_balance.balance, temp_hold_amount,
                sender_most_recent_balance.balance - temp_hold_amount, sender_most_recent_balance.count + 1)
        RETURNING id INTO temp_sender_new_balance_id;

        result.sender_balance_id = temp_sender_new_balance_id;
    END IF;

    --Finalize Transaction
    INSERT INTO finalized_transaction (transaction_id, canceled_at, request_id)
    VALUES (arg_transaction_id, now(), arg_request_id);

    UPDATE account SET user_id = sender_account.user_id WHERE id = sender_account.id;

    RETURN result;
END
$$;
