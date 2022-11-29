# Phase  3

- 2 Chains (2x14=28pts)
    - Chain 1 cust_sub_pay_hist
        - subtier ->sub -> cust_sub
        - customer -> cust_sub
        - cust_sub -> cust_sub_pay_hist
    - Chain 2 cust_sub_feat_pay_hist
        - subtier ->sub -> cust_sub
        - customer -> cust_sub
        - cust_sub -> cust_sub_featurepk -> cust_sub_feat_pay_hist
    - 2pt - chain easily identified {don't make it confusing - keep it easy to grade}
    - Procedure that inserts rows for entire chain
    - 2pts - each step is easily identified 
    - 10pts - chain produces 500,000+ rows
- 2+ views  (2x5pts=10pts) The two report. 
    - 2pts - appropriate name
    - 2pts - sql syntax is correct
    - 1pt - call & output provided
    ```sql
    CREATE or replace VIEW currentcustomers AS
    SELECT c.id, c.firstname, c.surname, c.username, cs.date_of_origin, s.numberofmonths, st.tiername
    FROM customer c inner join cust_sub cs on (c.id = cs.cust_id)
    inner join sub s on (s.id = cs.sub_id)
    inner join sub_tier st on (s.tier_id = st.id)
    WHERE (cs.active = true);
    select * from currentcustomers where (currentcustomers.id < 10);

    id|firstname|surname   |username|date_of_origin         |numberofmonths|tiername|
    --+---------+----------+--------+-----------------------+--------------+--------+
    1|Person0  |Personson0|User0   |2021-08-12 07:34:35.875|            12|Silver  |
    2|Person1  |Personson1|User1   |2021-07-22 16:06:51.897|            12|Gold    |
    3|Person2  |Personson2|User2   |2020-01-12 21:04:49.872|            12|Bronze  |
    4|Person3  |Personson3|User3   |2021-05-08 17:17:55.824|             1|Silver  |
    5|Person4  |Personson4|User4   |2020-11-19 22:27:50.227|             1|Silver  |
    6|Person5  |Personson5|User5   |2021-11-11 01:45:28.886|            12|Gold    |
    7|Person6  |Personson6|User6   |2021-02-13 21:04:32.678|             1|Bronze  |
    8|Person7  |Personson7|User7   |2020-03-07 03:46:53.270|            12|Silver  |
    9|Person8  |Personson8|User8   |2021-02-27 09:55:00.739|             1|Bronze  |
    ```
- 2+ plpgsql functions (2x5pts=10pts) Game_playable(returns bool) Can_login(returns bool)
    - 2pts - appropriate name, appropriate return type
    - 2pts - sql syntax is correct
    - 1pt - call & output provided

## Game_playable() takes a game id and a customer id
```sql
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

    
    select game_playable(8,3)
    game_playable|
    -------------+
    true         |
    select game_playable(8,9)
    game_playable|
    -------------+
    false        |
```

## can_login
```sql
CREATE OR REPLACE FUNCTION public.can_login(target_customer_id integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare 
	current_login_count int; 
	num_allowed_logins int; 
begin 
	
	select count(*) 
	into current_login_count
	from log_in_out_history lioh 
	where ((lioh.success = true)
			and (lioh.logout is null)
			and (lioh.customerid = 1)
		  );
	
	
	select st.concurrentlogin
	into num_allowed_logins
	from cust_sub cs inner join
	sub s on (cs.cust_id = target_customer_id  and cs.active = true and cs.sub_id = s.id) inner join 
	sub_tier st on (st.id = s.tier_id);
	
	return (current_login_count < num_allowed_logins);
end;

$function$
;


    select can_login(8) Takes a customer id
    can_login|
    ---------+
    false    |
```
- 2+ plpgsql procedures(2x5pts=10pts) Simulate_Game_Play Renewing_subscription 

## Simuating a game play
```sql
CREATE OR REPLACE PROCEDURE public.simulate_playing_games(IN number_of_plays_per_game integer DEFAULT 10)
 LANGUAGE plpgsql
AS $procedure$
declare
	customer_curs cursor for select c.id from customer c; 
	cust_rec record; 
	game_ record; 
begin 
	open customer_curs;
	loop
		fetch customer_curs into cust_rec;
		exit when not found;
		for game_ in (
		select g.game_name, g.id from customer
		inner join cust_sub cs on (customer.id = cs.cust_id and customer.id = 1)
		left join cust_sub_featurepk csf on (cs.id = csf.cust_subid)
		left join featurepack f on (csf.featpkid = f.id)
		left join game_feat gf on (f.id = gf.feat_id)
		left join game g on (gf.game_id = g.id) 
		where (g.id is not null)
		Union (select g.game_name , g.id from game g where (g.public = true))
		)
		loop
			call play_game(game_.id, cust_rec.id);
		end loop; 
	end loop;
	close customer_curs; 
end;
$procedure$
;
call simulate_playing_games(1)

-- elephant
```
## Renewing Subs
```sql
    CREATE OR REPLACE PROCEDURE public.renew_sub(IN mycustsub record)
 LANGUAGE plpgsql
AS $procedure$
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
end;$procedure$
;

call renew_sub(2);



``` 
- 2pts - appropriate name
- 2pts - sql syntax is correct
- 1pt - call & output provided
- Architecture write up: (10pts)
    - List of what functions/procedures/views belong in the DB
    - 2pts - list is clear/correct
    - 3pts - reasoning is clear/correct
    - List of what functions/procedures/views belong in the Class   - Library (not in the DB)
    - 2pts - list is clear/correct
    - 3pts - reasoning is clear/correct