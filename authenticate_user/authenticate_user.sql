CREATE OR REPLACE FUNCTION authenticate_user(
    p_email VARCHAR,
    p_password VARCHAR
)
RETURNS TABLE (
    user_id INT,
    user_role VARCHAR,
    full_name VARCHAR,
    email VARCHAR,
    coin_balance INT,
    office VARCHAR
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_user RECORD;
BEGIN
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        RAISE EXCEPTION 'Email не может быть пустым';
    END IF;

    IF p_password IS NULL OR TRIM(p_password) = '' THEN
        RAISE EXCEPTION 'Пароль не может быть пустым';
    END IF;

    SELECT 
        u.id, 
        u.role, 
        u.full_name, 
        u.email, 
        u.password_hash,
        u.coin_balance,
        u.office
    INTO v_user
    FROM users u
    WHERE u.email = p_email;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пользователь не зарегистрирован!';
    END IF;

    IF v_user.password_hash = crypt(p_password, v_user.password_hash) THEN
        RETURN QUERY 
        SELECT 
            v_user.id, 
            v_user.role, 
            v_user.full_name, 
            v_user.email,
            v_user.coin_balance,
            v_user.office;
    ELSE
        RAISE EXCEPTION 'Неверный пароль!';
    END IF;
END;
$$;
