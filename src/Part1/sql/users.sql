drop table users;
CREATE TABLE users
(
        user_id serial primary key,
        user_name VARCHAR(100),
        country VARCHAR(100),
        job VARCHAR(100),
        email VARCHAR(100),
        client_ip VARCHAR(100),
        user_agent VARCHAR(200),
        birth VARCHAR(100),
        last_conn_date timestamp
);
