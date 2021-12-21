\connect test_db
DROP TABLE IF EXISTS t_users;
CREATE TABLE t_users (
	id serial PRIMARY KEY,
	first_name character varying(50) NOT NULL,
	last_name character varying(50) NOT NULL,
	city character varying(50) NOT NULL
);