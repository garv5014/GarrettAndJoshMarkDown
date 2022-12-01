# Phase  3

- 2 Chains (2x14=28pts)
### Procedure for seeding the chains

```sql
CREATE OR REPLACE PROCEDURE public.seed_chains(IN num_of_rows integer DEFAULT NULL::integer)
LANGUAGE plpgsql
AS $procedure$
begin 
    
    if num_of_rows is null then 
        call makecustomers(10); 
        call makesubtier();
        call makesubs();
        call make_login_history();
        call make_cust_sub();
        call make_developers();
        call make_games();
        call makefeaturepack();
        call make_games_to_featurepack();
        call makecust_sub_pay_hist();
        call make_cust_sub_feat();
        call makecust_sub_feat_pay_hist();
        call simulate_playing_games_random();
    else 
        call makecustomers(num_of_rows); -- no default
        call makesubtier(); -- no parameter
        call makesubs(); -- no parameter
        call make_cust_sub((num_of_rows %3) +1); -- num of contract per customer
        call makefeaturepack(); -- finite number of packs. No Default
        call makecust_sub_pay_hist(); --no parameters 
        call make_cust_sub_feat((num_of_rows%2) +1); -- number of potential contracts per customer
        call makecust_sub_feat_pay_hist(); -- no parameters
    end if;
end;
$procedure$
;
```


- Chain 1 cust_sub_pay_hist
    - subtier ->sub -> cust_sub
    - customer -> cust_sub
    - cust_sub -> cust_sub_pay_hist
### Output for chain one 
- There are 250000 customers and each has at least one cus_sub and at least one payment for that subscriprtion. 
```sql
    id    |cust_sub_id|pay_date               |amt   |description     |
------+-----------+-----------------------+------+----------------+
250001|     750002|2020-12-06 00:42:33.465| $5.00|Bronze not renew|
250000|     749999|2022-01-19 03:24:41.068| $6.80|Silver renew    |
249999|     749996|2022-11-24 06:24:03.398| $4.25|Bronze renew    |
249998|     749993|2021-10-28 11:55:26.889| $5.00|Bronze not renew|
249997|     749990|2020-12-29 14:32:30.019| $5.00|Bronze not renew|
249996|     749987|2022-01-24 03:38:32.323| $8.50|Gold renew      |
249995|     749984|2021-12-17 00:23:23.049| $4.25|Bronze renew    |
249994|     749981|2021-12-24 17:42:05.270| $8.00|Silver not renew|
249993|     749978|2021-10-09 03:16:05.779| $8.00|Silver not renew|
249992|     749975|2023-05-29 03:43:50.016| $8.00|Silver not renew|
249991|     749972|2022-06-22 15:11:36.470| $5.00|Bronze not renew|
249990|     749969|2023-06-27 11:31:38.697| $4.25|Bronze renew    |
```
- Chain 2 cust_sub_feat_pay_hist
    - subtier ->sub -> cust_sub
    - customer -> cust_sub
    - cust_sub -> cust_sub_featurepk -> cust_sub_feat_pay_hist
    - featurepack -> cust_sub_featurepk
### Output for chain two
```sql
id    |cust_sub_feat_id|pay_date               |amt  |description                      |
------+----------------+-----------------------+-----+---------------------------------+
750003|         1500006|2022-01-03 04:51:47.836|$2.00|DungeonDweller GamePack not renew|
750002|         1500004|2021-10-30 18:01:59.836|$3.00|HighSciFi GamePack renew         |
750001|         1500002|2022-05-27 04:15:42.739|$2.00|HighSciFi GamePack renew         |
750000|         1500000|2023-06-21 16:19:13.987|$2.00|Retro GamePack not renew         |
749999|         1499998|2021-07-16 16:54:20.505|$1.00|Retro GamePack renew             |
749998|         1499996|2021-06-03 13:22:00.307|$4.00|HighSciFi GamePack not renew     |
749997|         1499994|2022-02-19 09:25:08.544|$4.00|HighSciFi GamePack not renew     |
749996|         1499992|2022-04-24 12:38:45.024|$3.00|HighSciFi GamePack not renew     |
749995|         1499990|2022-06-12 20:50:40.819|$0.50|DungeonDweller GamePack renew    |
749994|         1499988|2023-03-13 02:31:18.825|$3.00|HighSciFi GamePack renew         |
749993|         1499986|2021-06-20 03:05:27.628|$4.00|HighSciFi GamePack not renew     |
749992|         1499984|2022-06-05 00:34:43.881|$3.00|HighSciFi GamePack not renew     |
749991|         1499982|2021-10-17 18:53:40.387|$3.00|HighSciFi GamePack not renew     |
749990|         1499980|2021-11-15 18:57:57.600|$4.00|HighSciFi GamePack not renew     |
749989|         1499978|2021-03-08 20:17:54.009|$4.00|HighSciFi GamePack not renew     |
```
- 2pt - chain easily identified {don't make it confusing - keep it easy to grade}
- Procedure that inserts rows for entire chain
- 2pts - each step is easily identified 
- 10pts - chain produces 500,000+ rows
# Views 
- 2+ views  (2x5pts=10pts) The two report. 
    - 2pts - appropriate name
    - 2pts - sql syntax is correct
    - 1pt - call & output provided

## Current Customer info
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

## BaseSubRevReport 
```sql
CREATE OR REPLACE FUNCTION public.generate_base_sub_rev_report(month_year timestamp without time zone)
 RETURNS TABLE(developer text, payout money, pay_month timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
declare 
	all_devs record; 
begin 
	for all_devs in( 
	select id, developername
	from developer
	)loop 
		Developer := all_devs.developername;
		payout := Base_Subscription_Revenue_Per_Dev(all_devs.id, month_year);
		Pay_Month := date_trunc('month', (month_year));
		return next;
	end loop;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.base_subscription_revenue_per_dev(dev_id integer, month_year timestamp without time zone)
 RETURNS money
 LANGUAGE plpgsql
AS $function$
declare 
	payPeriodUpperBound timestamp := date_trunc('month', (month_year));
    payPeriodLowerBound timestamp := date_trunc('month', (month_year + interval '1 month'));
   	devsum int;
   	allGameCount float := 0; 
   	devGameCount float := 0; 
   	baseSubRev money := 0; 
   	targetId int := dev_id;
begin 
		select count(g.id)
		into devGameCount
		from game as g inner join 
		gameplay_record as gr on (g.id = gr.gameid and targetid = g.dev_id and (
									gr.starttime > payPeriodUpperBound) and (
									gr.starttime < payPeriodLowerBound ));					
									
	
		select count(g.id)
		into allGameCount
		from game as g inner join 
		gameplay_record as gr on ( g.id = gr.gameid
									and gr.starttime > payPeriodUpperBound 
									and (gr.starttime < payPeriodLowerBound )  );
		
	select sum(csph.amt)
		into baseSubRev
		from cust_sub cs inner join
		cust_sub_pay_hist csph on (cs.id = csph.cust_sub_id
										and (csph.pay_date > payPeriodUpperBound )
										and (csph.pay_date < payPeriodLowerBound));
					
	if baseSubRev is null or allGameCount = 0 then 
	return 0;
	else 
	return ((devGameCount/allGameCount) * (.1 * baseSubRev));
	end if;
end;
$function$
;

developer       |payout|pay_month              |
----------------+------+-----------------------+
Game Company 1  | $0.17|2022-10-01 00:00:00.000|
Game Company 2  | $0.00|2022-10-01 00:00:00.000|
Game Company 3  | $0.24|2022-10-01 00:00:00.000|
Game Company 4  | $0.25|2022-10-01 00:00:00.000|
Game Company 5  | $0.26|2022-10-01 00:00:00.000|
Game Company 6  | $0.19|2022-10-01 00:00:00.000|
Game Company 7  | $0.25|2022-10-01 00:00:00.000|
Game Company 8  | $0.00|2022-10-01 00:00:00.000|
Game Company 9  | $0.17|2022-10-01 00:00:00.000|
Game Company 10 | $0.17|2022-10-01 00:00:00.000|
```
# Functions
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
# Procedures 
- 2+ plpgsql procedures(2x5pts=10pts) Simulate_Game_Play Renewing_subscription 

## Simulating a game play
- We seeded the azure database with only 10000 customers which means we had 1000 gamdevs each with at least one game. We had ever customer try to play every game twice and we got 7 million plus gameplays.
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
call simulate_playing_games()

--output
id     |cust_subid|gameid|starttime              |duration       |
-------+----------+------+-----------------------+---------------+
7377561|     10001|   235|2022-08-27 15:09:16.243|06:24:23.550391|
7377560|     10001|   361|2021-09-06 10:33:39.196|03:49:36.479076|
7377559|     10001|   256|2022-03-20 13:42:19.584|04:47:44.197318|
7377558|     10001|   111|2021-07-01 09:36:12.009|07:08:57.685658|
7377557|     10001|   102|2022-09-22 03:03:15.264|05:03:19.045598|
7377556|     10001|   976|2022-09-14 11:01:16.780|01:12:22.496091|
7377555|     10001|   604|2021-05-12 23:18:46.195|00:51:04.734999|
7377554|     10001|   183|2021-11-28 20:03:23.788|01:41:05.963669|
7377553|     10001|   201|2020-11-17 10:57:34.473|03:02:32.444698|
7377552|     10001|   661|2021-07-04 12:25:42.585|00:49:02.956269|
7377551|     10001|   273|2021-09-18 05:43:11.712|06:54:38.576394|
7377550|     10001|    94|2021-10-20 15:56:33.705| 00:36:55.00417|


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

--ouput 
--before renew procedure ran
/*
id|cust_subid|featpkid|autorenew|current_term_start     |current_term_end       |numberofmonths|date_of_origin         |
--+----------+--------+---------+-----------------------+-----------------------+--------------+-----------------------+
 1|         1|       1|false    |2022-11-17 18:59:18.048|2022-12-17 18:59:18.048|             1|2022-11-17 18:59:18.048|
 2|         2|       2|true     |2022-11-17 18:59:18.048|2023-11-17 18:59:18.048|            12|2022-11-17 18:59:18.048|
 4|         1|       1|true     |2022-09-22 18:59:17.970|2022-10-22 18:59:17.970|             1|2018-11-17 18:59:17.970|

 --after renew procedure ran
 id|cust_subid|featpkid|autorenew|current_term_start     |current_term_end       |numberofmonths|date_of_origin    |
--+----------+--------+---------+-----------------------+-----------------------+--------------+-----------------------+
 1|         1|       1|false    |2022-11-17 18:59:18.048|2022-12-17 18:59:18.048|             1|2022-11-17 18:59:18.048|
 2|         2|       2|true     |2022-11-17 18:59:18.048|2023-11-17 18:59:18.048|            12|2022-11-17 18:59:18.048|
 4|         1|       1|true     |2022-10-22 18:59:17.970|2022-11-17 00:00:00.000|             1|2018-11-17 18:59:17.970|
 */


``` 
- 2pts - appropriate name
- 2pts - sql syntax is correct
- 1pt - call & output provided

# Architecture
- Architecture write up: (10pts)
    ## List of what functions/procedures/views belong in the DB
    - Simulating a Game play. We think that this would e a good fit on the database because it deals with data integrity of not letting users play games they aren't suppose to. Thus stopping bad data from being insereted in the game_record table. 
    - Renewing a subscription. We plan to have this procedure be ran by the schedular every x amount of time to autorenew subscription that have opted in. 
    - Adding a new game. This is a simple insertion of data that only developers should have access to so to help maintain the database and so that it is fast we feel like the database would be a good home for this. 
    - Generating the reports. This functionality shouldn't change to much so the database is a good place for it. It will make the api call really simple so that we just call the function and then display the results.
        - 2pts - list is clear/correct
        - 3pts - reasoning is clear/correct
    ## List of what functions/procedures/views belong in the Class   
    - Making a new customer and adding their subscription. We think it works for the api due us getting there credentials from a form rather then in the database. Then with that information we can connect them to a subscription. 
    - Can_login and Can_play. These two functions are mainly incharge of enforcing business logic so it makes sense for them to be in the api. But it would also be easy to writes these in teh database and just call them when needed. 
        - 2pts - list is clear/correct
        - 3pts - reasoning is clear/correct