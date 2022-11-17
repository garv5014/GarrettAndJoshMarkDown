
set search_path to public;
drop table if exists  cust_sub cascade;
drop table if exists cust_sub_featurepk cascade;
drop table if exists customer cascade;
drop table if exists developer cascade;
drop table if exists featurepack cascade;
drop table if exists game cascade;
drop table if exists game_feat cascade;
drop table if exists gameplay_record  cascade;
drop table if exists log_in_out_history cascade;
drop table if exists sub cascade;
drop table if exists sub_tier cascade;
drop table if exists cust_sub_pay_hist cascade;
drop table if exists cust_sub_feat_pay_hist cascade;

CREATE TABLE customer (
	id serial4 NOT NULL,
	email text null unique,
	firstname text null,
	surname text null,
	username text null unique,
	password_ text null,
	payment_info text null,
	CONSTRAINT customer_pk PRIMARY KEY (id),
	unique(username)
);

CREATE TABLE log_in_out_history (
	id serial4 NOT NULL,
	success bool null,
	customerid int4 not null,
	login timestamp null,
	logout timestamp null,
	CONSTRAINT log_in_out_history_pk PRIMARY KEY (id)
);
ALTER TABLE  log_in_out_history ADD CONSTRAINT log_in_out_history_fk FOREIGN KEY (customerid) REFERENCES customer(id)
on delete set null;

CREATE TABLE developer (
	id serial4 NOT NULL,
	developername text null unique,
	company_address text null unique,
	CONSTRAINT developer_pk PRIMARY KEY (id)
);


CREATE TABLE featurepack (
	id serial4 NOT NULL,
	pack_name text NULL,
	baseprice money null,
	active bool null constraint active check (true or null),
	CONSTRAINT featurepack_pk PRIMARY KEY (id),
	unique (pack_name, active)
);


CREATE TABLE game (
	id serial4 NOT NULL,
	game_name text NULL,
	dev_id int4 not null,
	public bool null,
	CONSTRAINT game_pk PRIMARY KEY (id),
	unique (game_name)
);
ALTER TABLE  game ADD CONSTRAINT game_fk FOREIGN KEY (dev_id) REFERENCES developer(id)
on delete set null;

create table game_feat (
	id serial4 not null,
	game_id int4 not null,
	feat_id int4 not null,
	constraint game_feat_pk primary key (id),
	unique (game_id, feat_id)
);
ALTER TABLE  game_feat ADD CONSTRAINT game_feat_fk FOREIGN KEY (game_id) REFERENCES game(id)
on delete set null;
ALTER TABLE  game_feat ADD CONSTRAINT game__feat1_fk FOREIGN KEY (feat_id) REFERENCES featurepack(id)
on delete set null;

CREATE TABLE sub_tier (
	id serial4 NOT NULL,
	baseprice money null,
	tiername text NULL,
	concurrentlogin int4 null,
	active bool null constraint active check ( true or null) ,
	unique(tiername, active),
	
	CONSTRAINT sub_tier_pk PRIMARY KEY (id)
);

CREATE TABLE sub (
	id serial4 NOT NULL,
	tier_id int4 not NULL,
	numberofmonths int4 null,

	CONSTRAINT sub_pk PRIMARY KEY (id)
);
ALTER TABLE  sub ADD CONSTRAINT sub_fk_1 FOREIGN KEY (tier_id) REFERENCES sub_tier(id)
on delete set null;

CREATE TABLE cust_sub (
	id serial4 NOT NULL,
	cust_id int4 not null,
	sub_id int4 not null,
	current_term_start timestamp not null,
	current_term_exp timestamp not null constraint exp_greater_then_start check(current_term_exp > current_term_start),
	date_of_origin timestamp null,
	autorenew bool null,
	active bool null constraint notneg check (true or null),
	unique(cust_id, active),
	CONSTRAINT cust_sub_pk PRIMARY KEY (id)
);




ALTER TABLE  cust_sub ADD CONSTRAINT cust_sub_fk FOREIGN KEY (cust_id) REFERENCES customer(id)
on delete set null;

ALTER TABLE  cust_sub ADD CONSTRAINT cust_sub_1_fk FOREIGN KEY (sub_id) REFERENCES sub(id)
on delete set null;


create table cust_sub_pay_hist (
	id serial4 not null,
	cust_sub_id int4 not null,
	pay_date timestamp not null,
	amt money not null constraint notnegative check(amt > 0::money),
	description text null,
	constraint cust_sub_pay_hist_pk primary key (id)
);

ALTER TABLE  cust_sub_pay_hist ADD CONSTRAINT cust_sub_pay_hist_fk FOREIGN KEY (cust_sub_id) REFERENCES cust_sub(id)
on delete set null;

CREATE TABLE cust_sub_featurepk (
	id serial4 NOT NULL,
	cust_subid int4 not NULL,
	featpkid int4 not null,
	autorenew bool null,
	current_term_start timestamp not null,
	current_term_end timestamp not null,
	numberofmonths int null,
	date_of_origin timestamp not null,
	CONSTRAINT cust_sub_featurepk_pk PRIMARY KEY (id)
);

ALTER TABLE  cust_sub_featurepk ADD CONSTRAINT cust_sub_featpk1_fk FOREIGN KEY (cust_subid) REFERENCES cust_sub(id)
on delete set null;

ALTER TABLE  cust_sub_featurepk ADD CONSTRAINT cust_sub_featpk_fk FOREIGN KEY (featpkid) REFERENCES featurepack(id)
on delete set null;

create table cust_sub_feat_pay_hist (
	id serial4 not null,
	cust_sub_feat_id int4 not null,
	pay_date timestamp not null,
	amt money not null constraint notneg check (amt > 0::money),
	description text null,
	constraint cust_sub_feat_pay_hist_pk primary key (id)
);

ALTER TABLE  cust_sub_feat_pay_hist ADD CONSTRAINT cust_sub_feat_pay_hist_fk FOREIGN KEY (cust_sub_feat_id) references cust_sub_featurepk(id)
on delete set null;

CREATE TABLE gameplay_record (
	id serial4 NOT NULL,
	cust_subid serial4 not null,
	gameid serial4 not null,
	starttime timestamp null,
	duration interval null,
	CONSTRAINT cust_game_pk PRIMARY KEY (id)
);
ALTER TABLE  gameplay_record ADD CONSTRAINT gameplay_record_fk FOREIGN KEY (cust_subid) REFERENCES cust_sub(id)
on delete set null;
ALTER TABLE  gameplay_record ADD CONSTRAINT gameplay_record_fk_1 FOREIGN KEY (gameid) REFERENCES game(id)
on delete set null;




INSERT INTO customer
(email, firstname, surname, username, password_, payment_info)
VALUES('fake@fake.com', 'Faker', 'Fakerson', 'Username', 'Drowssap', '1234 5678 9012'),
('aa@gmail.com', 'John', 'Smith', 'Doctor', 'TARDIS', '0987 6543 2156')
, ('bb@gmail.com', 'Chris', 'Smith', 'Boomer', 'Zoomer', '6543 0987 2156');

INSERT into log_in_out_history
(success, customerid, login, logout)
VALUES(true, 1, now(), now() + '30 minutes');

INSERT INTO log_in_out_history
(success, customerid, login)
VALUES(true, 1, now()- interval '1 day');



INSERT INTO developer
(developername, company_address)
VALUES('Valve', '42 Wallaby Way, Sydney, Australia'), ('Sega', '2643 N, 736 E, Green Hill, WY, USA');

INSERT INTO featurepack
(pack_name, baseprice, active)
values('Retro', 5.00, true), ('Sci-fi', 3.00, true);


INSERT INTO game
(game_name, dev_id, public)
VALUES('Portal 3', 1, true), ('Sonic the Hedgehog', 2, false), ('Shovel Knight', 2, false);

INSERT INTO game_feat
(game_id, feat_id)
VALUES(2, 1), (3,2);

INSERT INTO sub_tier
(baseprice, tiername, concurrentlogin, active)
VALUES(10, 'Gold', 5, true),(8, 'Silver', 2, true),(5, 'Bronze', 1, true), (6, 'Silver', 2, false);

INSERT INTO sub
(tier_id, numberofmonths)
VALUES(1, 1), (1, 12),(2, 1), (2, 12),(3, 1), (3, 12),(4, 1), (4, 12);



INSERT INTO cust_sub
(cust_id, sub_id, current_term_start, current_term_exp, date_of_origin, autorenew,active)
VALUES(1, 1, now(), now() + '1 month', now(), true, true), 
(2, 2, now() + '1 day', now() + '1 year', now(), false, true), 
(2, 1, '2022-10-11', '2022-11-11', now(), true, null),
(3, 1, '2022-10-11', '2022-11-11', now(), true, true);

INSERT INTO cust_sub_pay_hist
(cust_sub_id, pay_date, amt, description)
VALUES(1, '2022-11-27', 8.5, 'got the auto renew discount'),(2, '2022-11-26', 100, 'Base Price');


INSERT INTO cust_sub_featurepk
(cust_subid, featpkid, autorenew, current_term_start, current_term_end, numberofmonths, date_of_origin)
VALUES(1, 1, false, now(), now() + '1 month', 1, now()),
(2, 2, true, now(), now() + '1 year', 12, now());

INSERT INTO public.cust_sub_feat_pay_hist
(cust_sub_feat_id, pay_date, amt, description)
VALUES(1, '2022-11-25', 5, ''),(2, '2022-11-24', 20, '');


INSERT INTO gameplay_record
(cust_subid, gameid, starttime, duration)
VALUES(1, 1, now(), '1 hour 37 minutes 14 seconds'), (2, 2, now(), '1 week'), (2, 2, now(), '1 month');
