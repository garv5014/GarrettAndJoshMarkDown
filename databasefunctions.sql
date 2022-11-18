
--get number of concurrent logins for all users

select lioh.customerid, count(*)
from log_in_out_history lioh 
where (logout is null)
group by lioh.customerid;


--get list of games a user can play
select g.game_name from customer
inner join cust_sub cs on (customer.id = cs.cust_id and customer.id = 1)
inner join cust_sub_featurepk csf on (cs.id = csf.cust_subid)
inner join featurepack f on (csf.featpkid = f.id)
inner join game_feat gf on (f.id = gf.feat_id)
inner join game g on (gf.game_id = g.id or (g.public = true));

--Get subscription history
select c.firstname, c.surname , cs.date_of_origin , 
s.numberofmonths , st.tiername
from public.customer c
inner join public.cust_sub cs on (c.id = cs.cust_id)
inner join public.sub s on (s.id = cs.sub_id)
inner join public.sub_tier st on (s.tier_id = st.id);
--where c.id = target;


select g.game_name , d.developername , sum(gr.duration)
    from gameplay_record gr
    inner join game g on (g.id = gr.gameid)
    inner join developer d on (g.dev_id = d.id)
    group by 1,2
    order by sum(gr.duration) desc;
   
   
call find_renewable();  

create or replace procedure find_renewable_fp()
language plpgsql 
as $$
declare
renew record;

begin 
	for renew in 
	select id, cust_subid, current_term_end, date_of_origin, autorenew, f.active
	from cust_sub_featurepk csf inner join featurepack f on (csf.featpkid = f.id) order by 4 desc
	loop
		if(renew.autorenew and (now() - renew.current_term_exp >= '1 second') and renew.active = true) then
		 call renew_sub_fp(renew);
		end if;
	end loop;

end;$$

create or replace procedure renew_sub_fp(mycustsub record)
language plpgsql 
as $$
declare
subprice money;
submonths int;
tempexp timestamp;
tempmonths text;
begin 
	subprice = fp.baseprice from cust_sub_featurepack csf
	inner join featurepack fp on (fp.id = csf.featpkid)
	where (csf.id = mycustsub.id);

	submonths = s.numberofmonths from cust_sub
	inner join sub s on (s.id = cust_sub.sub_id)
	where (cust_sub.id = mycustsub.id);

	tempmonths = submonths||' months';
	tempexp = mycustsub.current_term_exp + tempmonths::interval;
	tempexp = date_trunc('month', tempexp);
	tempmonths = date_part('day', mycustsub.date_of_origin)||' days';
	tempexp = tempexp + tempmonths::interval;
	if(date_part('day', tempexp) < date_part('day', mycustsub.date_of_origin)) then
	tempexp = date_trunc('month', tempexp);
	tempexp = tempexp + date_part(
        'days', 
        (date_trunc('month', tempexp) + '1 month - 1 day'::interval)
        );
	end if;
	if(mycustsub.autorenew = true) then
	subprice = subprice - 1;
	end if;
	INSERT INTO public.cust_sub__feat_pay_hist
	(cust_sub_id, pay_date, amt, description)
	VALUES(mycustsub.id, now(), subprice, 'renew subscription on featurepack');
		
	UPDATE public.cust_sub_featurepk 
	SET current_term_start= current_term_end, current_term_end= tempexp - '1 day'::interval
	WHERE id=mycustsub.id;
end;$$

create or replace procedure find_renewable()
language plpgsql 
as $$
declare
renew record;

begin 
	for renew in 
	select id, cust_id, sub_id, current_term_exp, date_of_origin, autorenew, active
	from cust_sub order by 4 desc
	loop
		if(renew.autorenew and (now() - renew.current_term_exp >= '1 second') and renew.active = true) then
		 call renew_sub(renew);
		end if;
	end loop;

end;$$

create or replace procedure renew_sub(mycustsub record)
language plpgsql 
as $$
declare
subprice money;
submonths int;
tempexp timestamp;
tempmonths text;
begin 
	subprice = st.baseprice from cust_sub 
	inner join sub on (mycustsub.sub_id = sub.id)
	inner join sub_tier st on (st.id = sub.tier_id)
	where (cust_sub.id = mycustsub.id);

	submonths = s.numberofmonths from cust_sub
	inner join sub s on (s.id = cust_sub.sub_id)
	where (cust_sub.id = mycustsub.id);
	tempmonths = submonths||' months';
	tempexp = mycustsub.current_term_exp + tempmonths::interval;
	tempexp = date_trunc('month', tempexp);
	tempmonths = date_part('day', mycustsub.date_of_origin)||' days';
	tempexp = tempexp + tempmonths::interval;
	if(date_part('day', tempexp) < date_part('day', mycustsub.date_of_origin)) then
	tempexp = date_trunc('month', tempexp);
	tempexp = tempexp + date_part(
        'days', 
        (date_trunc('month', tempexp) + '1 month - 1 day'::interval)
        );
	end if;
	if(mycustsub.autorenew = true) then
	subprice = subprice * .85;
	end if;
	INSERT INTO public.cust_sub_pay_hist
	(cust_sub_id, pay_date, amt, description)
	VALUES(mycustsub.id, now(), subprice, 'renew subscription');
		
	UPDATE public.cust_sub
	SET current_term_start= current_term_exp, current_term_exp= tempexp - '1 day'::interval
	WHERE id=mycustsub.id;
end;$$

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
	INSERT INTO public.featurepack
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
	  	 namename = '';
	  	 for randcount in 0..2 by 1 loop 
		  	 
	  	 	for idcount in 0..3 by 1 loop
	  	 		namename = namename||(((random() * 10)::int) - 1);
	  	 	end loop;
	  	 		namename = namename||' ';
	  	 end loop;
	  	 
	  	 INSERT INTO public.customer
	(email, firstname, surname, username, password_, payment_info)
	VALUES('email'||coun||'@email.com', 'Person'||coun, 'Personson'||coun, 'User'||coun, 'password'||coun, namename);
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
;--makes cust_sub_featurepack
CREATE OR REPLACE PROCEDURE public.make_cust_sub_feat(IN number_of_potential_contracts integer DEFAULT 1)
 LANGUAGE plpgsql
AS $procedure$
declare 
	cust_curs cursor for select * from cust_sub; 
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
				f.id 
			into rSub
			FROM
				featurepack f OFFSET floor(random() * (
					SELECT
						COUNT(*)
						FROM featurepack))
			LIMIT 1;
			
			origin_date :='2020-01-01'::timestamp + (random() * (interval '2 years')) + '0 days';
			temp_term_start := origin_date + (random() * (interval '2 years')) + '0 days'; 
		
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
			if((cust_current.id % 2) = 0) then
			insert into cust_sub_featurepk 
			(cust_subid, featpkid, current_term_start, current_term_end, date_of_origin, autorenew,active, numberofmonths)
			values (cust_current.id, rsub, temp_term_start,  temp_term_start + '1 month', origin_date, temp_autorenew, temp_active, 1);
			else
			insert into cust_sub_featurepk 
			(cust_subid, featpkid, current_term_start, current_term_end, date_of_origin, autorenew,active, numberofmonths)
			values (cust_current.id, rsub, temp_term_start, temp_term_start + '1 year', origin_date, temp_autorenew, temp_active, 12);
			end if;
		end loop;
	end loop;
	close cust_curs; 
end;$procedure$
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
CREATE OR REPLACE FUNCTION public.game_playable(gameid integer, custid integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare 
	all_feat_for_game record;
	target_game int := gameid;
	game_count int; 
begin
	select count(*)
	into game_count
	from (
	((select g.game_name, g.id from customer
    inner join cust_sub cs on (customer.id = cs.cust_id and customer.id = custid)
    left join cust_sub_featurepk csf on (cs.id = csf.cust_subid)
    left join featurepack f on (csf.featpkid = f.id)
    left join game_feat gf on (f.id = gf.feat_id)
	left join game g on (gf.game_id = g.id) 
	where (g.id is not null and g.id = gameid)) )
    Union (select g.game_name , g.id from game g where (g.public = true and g.id = gameid) )) as x;
	
   	if game_count > 0 then 
   	return true;
   	else
   	return false;
   	end if; 
end;
$function$
;


CREATE OR REPLACE PROCEDURE public.make_cust_sub(IN number_of_potential_contracts integer DEFAULT 1)
 LANGUAGE plpgsql
AS $procedure$
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
$procedure$
;


create or replace procedure makecust_sub_pay_hist(counter int)
language plpgsql 
as $$
declare

begin 
  	 --needed: using dates from above, run the renew function until we're at the present day
	--occasionally update a cust_sub to not renew.
 commit;
	
end;$$

CREATE OR REPLACE PROCEDURE public.make_login_history(IN number_of_logins_per_cust integer)
 LANGUAGE plpgsql
AS $procedure$
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
$procedure$
;

create or replace procedure makecust_sub_featurepk(counter int)
language plpgsql 
as $$
declare

begin 
  	 --70% of customers have 1 feature pack
     --50% of those have 2
	 --25% of those have 3
 commit;

end;$$
create or replace procedure makecust_sub_featurepk_pay_hist(counter int)
language plpgsql 
as $$
declare

begin 
  	 ----needed: using dates from above, run the renew function until we're at the present day
	--occasionally update a cust_sub to not renew.
 commit;

end;$$

create or replace procedure make_developers(num_of_dev int default 10) 
language plpgsql as 
$$
declare 
	dev_id int;
begin 
	for t in 1..num_of_dev by 1 
	loop 
		insert into developer 
		(developername, company_address)
		values ('', '')
	returning id into dev_id;
	update developer 
	set developername = 'Game Company ' || dev_id,
		company_address = 'Company on ' || dev_id || ' Sesame St NY, US'
	where (id = dev_id);
	end loop; 
end;
$$


create or replace procedure make_Games(num_of_games_per_dev int default 10) 
language plpgsql as 
$$
declare 
	all_devs_curs cursor for select d.developername, id from developer d; 
	current_dev record;
	temp_game_id int;
	rDeterminer int; 
	rMod int; 
	temp_public bool; 
begin 
	
	open all_devs_curs;
	loop
		
		fetch all_devs_curs into current_dev;
		exit when not found;
		for t in 1..num_of_games_per_dev by 1
		loop
		select (random() * 100) 
			into rDeterminer;
		select (random() * 10)
			into rMod;
		if rMod = 0 or rDeterminer % rMod = 0 then
		temp_public := true;
		else
		temp_public := false;
		end if;
				insert into game 
				(game_name, dev_id, public) 
				values ('', current_dev.id, temp_public ) returning id into temp_game_id;
			update game 
			set game_name = 'Game ' || temp_game_id
			where (game.id = temp_game_id );
			end loop;
	end loop;
end;
$$ 


create or replace procedure connect_games_to_featurepack() 
language plpgsql as 
$$
declare 
	private_games_curs cursor for select g.id from game g where (public = false);
	all_private_games record; 
	game_feat_count int; 
	feat_count int;
	Feat int; 
begin 
	select count(*)
	into feat_count
	from featurepack; 
	 open private_games_curs;
		loop
			fetch private_games_curs into all_private_games;
			exit when not found;
			Feat := all_private_games.id % feat_count; 
			if Feat <> 0 and  Feat = 1 then
			INSERT INTO public.game_feat (game_id, feat_id) VALUES(all_private_games.id, Feat);
			INSERT INTO public.game_feat (game_id, feat_id) VALUES(all_private_games.id, Feat+1);
			elseif Feat <> 0 then
			INSERT INTO public.game_feat (game_id, feat_id) VALUES(all_private_games.id, Feat);
			else
			end if;
		end loop; 
	close private_games_curs;
end;
$$

create or replace procedure makegameplay_record(counter int)
language plpgsql 
as $$
declare

begin 
  	 	--this one feels tricky
		--each feature pack gets 25% of rows 
		--only get user_sub ids where they have access to that game
		--each duration is a random number of minutes, from 1 to 300
 commit;

end;$$


create or replace procedure find_renewable_fp()
language plpgsql 
as $$
declare
renew record;
isactive bool;
begin 
	for renew in 
	select id , cust_subid, featpkid, current_term_end, date_of_origin, autorenew 
	from cust_sub_featurepk csf order by 4 desc loop
		isactive = f.active from featurepack f where (renew.featpkid = f.id);
		if(renew.autorenew and (now() - renew.current_term_end >= '1 second') and isactive = true) then
		 call renew_sub_fp(renew);
		end if;
	end loop;

end;$$



create or replace procedure renew_sub_fp(mycustsub record)
language plpgsql 
as $$
declare
subprice money;
submonths int;
tempexp timestamp;
tempmonths text;
begin 
	subprice = fp.baseprice from cust_sub_featurepk csf
	inner join featurepack fp on (fp.id = csf.featpkid)
	where (csf.id = mycustsub.id);

	submonths = s.numberofmonths from cust_sub
	inner join sub s on (s.id = cust_sub.sub_id)
	where (cust_sub.id = mycustsub.id);

	tempmonths = submonths||' months';
	tempexp = mycustsub.current_term_end + tempmonths::interval;
	tempexp = date_trunc('month', tempexp);
	tempmonths = date_part('day', mycustsub.date_of_origin)||' days';
	tempexp = tempexp + tempmonths::interval;

	if(date_part('day', tempexp) < date_part('day', mycustsub.date_of_origin)) then
	tempexp = date_trunc('month', tempexp);
	tempexp = tempexp + date_part(
        'days', 
        (date_trunc('month', tempexp) + '1 month - 1 day'::interval)
        );
	end if;

	if(mycustsub.autorenew = true) then
	subprice = subprice - 1::money;
	end if;
	INSERT INTO public.cust_sub_feat_pay_hist
	(cust_sub_feat_id, pay_date, amt, description)
	VALUES(mycustsub.id, now(), subprice, 'renew subscription on featurepack');


	UPDATE public.cust_sub_featurepk 
	SET current_term_start= current_term_end, current_term_end = (tempexp - '1 day'::interval)
	WHERE id=mycustsub.id;
end;$$

create or replace procedure find_renewable()
language plpgsql 
as $$
declare
renew record;

begin 
	for renew in 
	select id, cust_id, sub_id, current_term_exp, date_of_origin, autorenew, active
	from cust_sub order by 4 desc
	loop
		if(renew.autorenew and (now() - renew.current_term_exp >= '1 second') and renew.active = true) then
		 call renew_sub(renew);
		end if;
	end loop;

end;$$

create or replace procedure renew_sub(mycustsub record)
language plpgsql 
as $$
declare
subprice money;
submonths int;
tempexp timestamp;
tempmonths text;
begin 
	subprice = st.baseprice from cust_sub 
	inner join sub on (mycustsub.sub_id = sub.id)
	inner join sub_tier st on (st.id = sub.tier_id)
	where (cust_sub.id = mycustsub.id);

	submonths = s.numberofmonths from cust_sub
	inner join sub s on (s.id = cust_sub.sub_id)
	where (cust_sub.id = mycustsub.id);
	tempmonths = submonths||' months';
	tempexp = mycustsub.current_term_exp + tempmonths::interval;
	tempexp = date_trunc('month', tempexp);
	tempmonths = date_part('day', mycustsub.date_of_origin)||' days';
	tempexp = tempexp + tempmonths::interval;
	if(date_part('day', tempexp) < date_part('day', mycustsub.date_of_origin)) then
	tempexp = date_trunc('month', tempexp);
	tempexp = tempexp + date_part(
        'days', 
        (date_trunc('month', tempexp) + '1 month - 1 day'::interval)
        );
	end if;
	if(mycustsub.autorenew = true) then
	subprice = subprice * .85;
	end if;
	INSERT INTO public.cust_sub_pay_hist
	(cust_sub_id, pay_date, amt, description)
	VALUES(mycustsub.id, now(), subprice, 'renew subscription');
		
	UPDATE public.cust_sub
	SET current_term_start= current_term_exp, current_term_exp= tempexp - '1 day'::interval
	WHERE id=mycustsub.id;
end;$$
