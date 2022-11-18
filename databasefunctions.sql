
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
select * from customer;

call makecustomers(10);
create or replace procedure makecust_sub(counter int)
language plpgsql 
as $$
declare

begin 
  	 --needed: get random date within a span of 2 years
 commit;
	
end;$$

create or replace procedure makecust_sub_pay_hist(counter int)
language plpgsql 
as $$
declare

begin 
  	 --needed: using dates from above, run the renew function until we're at the present day
	--occasionally update a cust_sub to not renew.
 commit;
	
end;$$

create or replace procedure makelog_in_out_history(counter int)
language plpgsql 
as $$
declare

begin 
  	 --pick random date for login
	--70% work as login
	--50% of those log out
	--duration set as a random number of hours
 commit;
	
end;$$

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

create or replace procedure makedeveloper(counter int)
language plpgsql 
as $$
declare

begin 
  	 ----Generate 1/10 of expected developers
 commit;

end;$$
create or replace procedure makegame(counter int)
language plpgsql 
as $$
declare

begin 
  	 ----Generate 10 games per developer of expected developers
 commit;

end;$$
create or replace procedure makegame_feat(counter int)
language plpgsql 
as $$
declare

begin 
  	--75% of games go into a feature pack
	--1/3 of those go into each one
 commit;

end;$$

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
