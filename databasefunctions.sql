--limited number functions
create or replace procedure makesubtier()
language plpgsql 
as $$
declare

begin 
	INSERT INTO public.sub_tier
	(baseprice, tiername, concurrentlogin, active)
	VALUES(5.00, 'Bronze', 1, true), 
	(8.00, 'Silver', 2, true),
	(10.00, 'Gold', 5, true);
end;$$
	



create or replace procedure makesubs()
language plpgsql 
as $$
declare
subtier record;
begin 
	for subtier in
	select id from sub_tier s loop
	INSERT INTO public.sub
	(tier_id, numberofmonths)
	VALUES(subtier.id, 1),(subtier.id, 12); 
	end loop;
end;$$
	

create or replace procedure makefeaturepack()
language plpgsql 
as $$
declare

begin 
	INSERT INTO featurepack
	(pack_name, baseprice, active)
	VALUES('Retro GamePack', 3, true),
	('HighSciFi GamePack', 4, true),
	('DungeonDweller GamePack', 2, true);

end;$$

--not limited. Each one should take in an int for the number of records
create or replace procedure makecustomers(counter int)
language plpgsql 
as $$
declare
randomnum int;
namename text = '';
begin 
  	 for coun in 0..counter by 1 loop
	  	 for randcount in 0..2 by 1 loop 
		  	 
	  	 	for idcount in 0..3 by 1 loop
	  	 		namename = namename||(random() * 10)::int;
	  	 	end loop;
	  	 		namename = namename||' ';
	  	 end loop;
	  	 
	  	 INSERT INTO public.customer
	(email, firstname, surname, username, password_, payment_info)
	VALUES('email'||coun||'@email.com', 'John'||coun, 'Smith'||coun, 'User'||coun, 'password'||coun, namename);
   	end loop;
 commit;
	
end;$$

-- make_cust_sub
CREATE OR REPLACE PROCEDURE make_cust_sub(IN number_of_potential_contracts integer DEFAULT 1)
 LANGUAGE plpgsql
AS $$
declare 
	cust_curs cursor for select * from customer; 
	cust_current record;
	rSub int;
	rDeterminer int;
	origin_date timestamp;
	temp_term_start timestamp;
	temp_term_exp timestamp;
	temp_active bool; 
	temp_autorenew bool;
	temp_interval text;
begin 
	
	open cust_curs;
	loop
		fetch cust_curs into cust_current;
		exit when not found;
	
		for t in 0..number_of_potential_contracts by 1 
		loop 
			
			SELECT
				sub.id 
			into rSub
			FROM
				sub OFFSET floor(random() * (
					SELECT
						COUNT(*)
						FROM sub))
			LIMIT 1;
			
			origin_date :='2020-01-01'::timestamp + (random() * (interval '2 years')) + '0 days';
			temp_term_start := origin_date + (random() * (interval '2 years')) + '0 days'; 
		
			select s.numberofmonths
			into temp_interval
			from sub s 
			where (rSub = s.id);
			temp_interval := temp_interval || ' months';
			temp_term_exp := temp_term_start + temp_interval::interval;
			select (random() * 10) 
			into rDeterminer;
			
			if t = 1 then 
			temp_active = true;
			else 
			temp_active = null;
			end if;
		
			if rDeterminer % 4 = 0 then
			temp_autorenew = true;
			else
			temp_autorenew = null;
			end if;
			
			insert into cust_sub 
			(cust_id, sub_id, current_term_start, current_term_exp, date_of_origin, autorenew,active)
			values (cust_current.id, rsub, temp_term_start, temp_term_exp, origin_date, temp_autorenew, temp_active);
		end loop;
	end loop;
	close cust_curs; 
end;
$$
;

-- makes_login_history

CREATE OR REPLACE PROCEDURE public.make_login_history(IN number_of_logins_per_cust integer)
 LANGUAGE plpgsql
AS $$
declare 
	cust_curs cursor for select * from customer;
	current_cust record;
	rDeterminer int;
	mod_success bool;
	rlogin timestamp;
	rlogout timestamp; 
begin 
	
	open cust_curs; 
	loop
		
	fetch cust_curs into current_cust;
	exit when not found;
	
		for t in 0..number_of_logins_per_cust by 1
		loop 
			rlogin := null;
			rlogout := null;
			select (random() * 10) 
			into rDeterminer;
			rlogin :='2020-01-01'::timestamp + (random() * (interval '2 years')) + '0 days';
			if rDeterminer % 3 = 0 then 
			--failed to login
			mod_success = false;
			rlogout := rlogin +  '1 minute';
			else 
			--succeded login
			mod_success = true;
			if rDeterminer % 7 = 0 then
			rlogout := rlogin + (random() *  (interval'5 days'));
			end if;
			
			end if; 
			insert into log_in_out_history 
			(success, customerid,login,logout)
			values (mod_success, current_cust.id ,rlogin, rlogout);
		end loop;
		
	
	end loop;
	close cust_curs;
	
end;
$$
;

-- simulates a game being played
CREATE OR REPLACE PROCEDURE public.play_game(IN gameid integer, IN custid integer)
 LANGUAGE plpgsql
AS $procedure$
declare 
	cust_sub_id int; 
	game_feat record; 
	gameplay_record_id int;
	can_play bool;
	temp_record record;
	my_cursor cursor for select gf.game_id , gf.feat_id 
						from game_feat gf where (gf.game_id = gameid);
begin
	select cs.cust_id 
	into cust_sub_id
	from customer c inner join 
	cust_sub cs on(c.id = cs.cust_id)
	where (cs.cust_id = custid );
	 select game_playable(gameid, custid) into can_play;
	if can_play then 
		insert into gameplay_record 
		(cust_subid, gameid, starttime, duration)
		values (cust_sub_id, gameid, now(), null)
		returning "id" into gameplay_record_id;
		
		open my_cursor;
		loop
			fetch my_cursor into temp_record;
			exit when not found;
			insert into game_feature_pack_rev 
			(game_record_id, feature_pack_id) 
			values (temp_record.game_id, temp_record.feat_id);
		end loop;
		close my_cursor;
	else 
		raise exception using
            errcode='CPTGL',
            message='This customer can not play that game',
            hint='they are poor';
	end if; 
	
end; 
$procedure$
;

-- checks if a game is playable for a given customer.
CREATE OR REPLACE PROCEDURE public.play_game(IN gameid integer, IN custid integer)
 LANGUAGE plpgsql
AS $procedure$
declare 
	cust_sub_id int; 
	game_feat record; 
	gameplay_record_id int;
	can_play bool;
	temp_record record;
	my_cursor cursor for select gf.game_id , gf.feat_id 
						from game_feat gf where (gf.game_id = gameid);
begin
	select cs.cust_id 
	into cust_sub_id
	from customer c inner join 
	cust_sub cs on(c.id = cs.cust_id)
	where (cs.cust_id = custid );
	 select game_playable(gameid, custid) into can_play;
	if can_play then 
		insert into gameplay_record 
		(cust_subid, gameid, starttime, duration)
		values (cust_sub_id, gameid, now(), null)
		returning "id" into gameplay_record_id;
		
		open my_cursor;
		loop
			fetch my_cursor into temp_record;
			exit when not found;
			insert into game_feature_pack_rev 
			(game_record_id, feature_pack_id) 
			values (temp_record.game_id, temp_record.feat_id);
		end loop;
		close my_cursor;
	else 
		raise exception using
            errcode='CPTGL',
            message='This customer can not play that game',
            hint='they are poor';
	end if; 
	
end; 
$procedure$
;
