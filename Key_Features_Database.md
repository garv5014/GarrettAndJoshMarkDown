# Key Features
- We sell subscriptions to our online services at these levels:
    - Gold ($10/month or $100/year), 5 concurrent logins
    - Silver (8/month or  $80/year), 2 concurrent logins
    - Bronze ($5/month or $50/year), 1 concurrent login
	```sql 
    select * from sub_tier;
    ```
    -We can see the number of concurrent logins for each user (to enforce above information)
    ```sql
    select lioh.customerid, count(*)
    from log_in_out_history lioh 
    where (logout is null)
    group by lioh.customerid;
    
    customerid|count|
    ----------+-----+
             1|    1|
    ```
- We also sell feature packs that can be added to a subscription:
    - Retro GamePack (auto-renewal rates: $2/month, $20/year) (no-auto-renewal rate: $3/month)
    - HighSciFi GamePack ($3/month, $30/year) (no-auto-renewal rate: $4/month)
    - DungeonDweller GamePack ($1/month, $10/year) (no-auto-renewal rate: $2/month)
     ```sql
    select * from featurepack; select * from cust_sub_featurepk;
    
    ```
    - A feature pack can be active or inactive letting people be grandfathered in. Customers can't sign up for inactive feature packs

   
- Some games can only be accessed by the additional feature-packs 
```sql
-- we expect that customer 1 can play Portal(public) and Sonic(in a pack)  but not shovel knight
select g.game_name, g.id from customer
inner join cust_sub cs on (customer.id = cs.cust_id and customer.id = 1)
left join cust_sub_featurepk csf on (cs.id = csf.cust_subid)
left join featurepack f on (csf.featpkid = f.id)
left join game_feat gf on (f.id = gf.feat_id)
left join game g on (gf.game_id = g.id) 
where (g.id is not null)
Union (select g.game_name , g.id from game g where (g.public = true))
--game_name         |
--------------------+
--Portal 3          |
--Sonic the Hedgehog|
create or replace function game_playable(gameid int, custid int)
returns bool
language plpgsql as 
$$
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
$$;


```
    ```sql
    select * from cust_sub_featurepk;
    -- enforced via not null constraint
    ```
- Subscriptions can be auto-renewed on a monthly or annual basis
- Subcriptions are give a 15% discount at each auto-renewal
- Feature packs have their own auto-renewal cycle
- Feature packs can only be 'added' to a subscription (can not be purchased without a subscription)
    ```sql
    -- ability for autorenewal with discount
    select sub.numberofmonths, cust_sub.autorenew, cust_sub.sub_price
    -- look at functions for renewing subscriptions near the bottom (elephant)
    ``` 
- Users have one active subscription type, but multiple feature packs
    ```sql
    select numberofmonths, date_sub, exp_date, autorenew, feature_sub from cust_sub_featurepk;
    -- enforced via ERD
    ```
- A history of all prior subscriptions for a user needs to be easily produced
    ```sql
        --Get subscription history
        select c.firstname, c.surname , cs.date_of_origin , 
        s.numberofmonths , st.tiername
        from public.customer c
        inner join public.cust_sub cs on (c.id = cs.cust_id)
        inner join public.sub s on (s.id = cs.sub_id)
        inner join public.sub_tier st on (s.tier_id = st.id);
        --where c.id = target;
    ```

- Every time a user logs on to our service, 
    - we validate their account, (external autheniscation used) 
    - validate concurrent login limits
    ```sql
    select lioh.customerid, count(*)
    from log_in_out_history lioh 
    where (logout is null)
    group by lioh.customerid;

    ```
    - log the attempt (success or failure)
    ```sql
    select id, customerid, success, login from log_in_out_history;
    ```
- Every time the user plays a game we track it
    ```sql 
    select * from gameplay_record where (cust_subid = target)
    ```
- We can produce reports on which games get the most usage
    ```sql 
    select g.game_name , d.developername , sum(gr.duration)
    from gameplay_record gr
    inner join game g on (g.id = gr.gameid)
    inner join developer d on (g.dev_id = d.id)
    group by 1,2
    order by sum(gr.duration) desc; 
    ```
- Revenue Sharing:  We need to share a % of all our revenue with the game developers (look at the bottom for Functions for generating the report )
    - BaseSubscription Revenue Sharing
        - Calculate this based the formula
        ( DevelopersGamesPlayed/AllGamesPlayed ) * (10% of all BaseSubscription Revenue) => portion for that Developer Near The Bottom
    - FeaturePack Revenue Sharing
        - Calculate this based the formula
        ( DevelopersGamesInThisFeaturePackNumberOfGamesPlayed/AllGamesPlayedInThisFeaturePack ) * (10% of all This FeaturePack Subscription Revenue) => portion for that Developer Near The Bottom
        - Do that for each feature pack
    - provide a nice report that shows the calculations for each developer





- Renewals
    - Your data system has a way of enforcing renewals
    ```sql
    Select custid, autorenew from cust_sub;
    ```

    ```sql
    Select cust_subid, autorenew from cust_sub_featurepk
    ```
- Your system has a way of handling special renewal situations (look at functions for renewing a subscription)
    - example:  Purchase 11/30, renewed to 12/30, renewed to 1/30, but what happens in February?  What about March?
    - Hint: It will still need to end on 3/30
    - Consider 5/31 purchase and how it renews: 6/30, 7/31, 8/31, 9/30 ... etc

## Functions for renewing a subscription
```sql

--before renew procedure ran
/* 
id|cust_id|sub_id|current_term_start     |current_term_exp       |date_of_origin         |autorenew|active|
--+-------+------+-----------------------+-----------------------+-----------------------+---------+------+
 1|      1|     1|2022-11-16 20:43:28.635|2022-12-16 20:43:28.635|2022-11-16 20:43:28.635|true     |true  |
 2|      2|     2|2022-11-17 20:43:28.635|2023-11-16 20:43:28.635|2022-11-16 20:43:28.635|false    |true  |
 3|      2|     1|2022-10-11 00:00:00.000|2022-11-11 00:00:00.000|2022-11-16 20:43:28.635|true     |      |
 4|      3|     1|2022-10-11 00:00:00.000|2022-11-11 00:00:00.000|2022-11-16 20:43:28.635|true     |true  |
  */

 --after renew procedure ran
/*
 id|cust_id|sub_id|current_term_start     |current_term_exp       |date_of_origin         |autorenew|active|
--+-------+------+-----------------------+-----------------------+-----------------------+---------+------+
 1|      1|     1|2022-11-16 20:43:28.635|2022-12-16 20:43:28.635|2022-11-16 20:43:28.635|true     |true  |
 2|      2|     2|2022-11-17 20:43:28.635|2023-11-16 20:43:28.635|2022-11-16 20:43:28.635|false    |true  |
 3|      2|     1|2022-10-11 00:00:00.000|2022-11-11 00:00:00.000|2022-11-16 20:43:28.635|true     |      |
 4|      3|     1|2022-11-11 00:00:00.000|2022-12-16 00:00:00.000|2022-11-16 20:43:28.635|true     |true  | 
 */

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

```
## Functions for renewing a subscription pack
```sql

--before renew procedure ran
/*
id|cust_subid|featpkid|autorenew|current_term_start     |current_term_end       |numberofmonths|date_of_origin         |
--+----------+--------+---------+-----------------------+-----------------------+--------------+-----------------------+
 1|         1|       1|false    |2022-11-17 18:59:18.048|2022-12-17 18:59:18.048|             1|2022-11-17 18:59:18.048|
 2|         2|       2|true     |2022-11-17 18:59:18.048|2023-11-17 18:59:18.048|            12|2022-11-17 18:59:18.048|
 4|         1|       1|true     |2022-09-22 18:59:17.970|2022-10-22 18:59:17.970|             1|2018-11-17 18:59:17.970|

 --after renew procedure ran
 id|cust_subid|featpkid|autorenew|current_term_start     |current_term_end       |numberofmonths|date_of_origin         |
--+----------+--------+---------+-----------------------+-----------------------+--------------+-----------------------+
 1|         1|       1|false    |2022-11-17 18:59:18.048|2022-12-17 18:59:18.048|             1|2022-11-17 18:59:18.048|
 2|         2|       2|true     |2022-11-17 18:59:18.048|2023-11-17 18:59:18.048|            12|2022-11-17 18:59:18.048|
 4|         1|       1|true     |2022-10-22 18:59:17.970|2022-11-17 00:00:00.000|             1|2018-11-17 18:59:17.970|
 */

 ```

## Functions for generating the calculations
```sql
create or replace function  generate_base_sub_rev_report(month_year timestamp)
returns table (
	Developer text,
	payout money,
	Pay_Month timestamp
)
language plpgsql as 
$$
declare 
	all_devs record; 
begin 
	for all_devs in( 
	select id, developername
	from developer
	)loop 
		Developer := all_devs.developername;
		payout := Base_Subscription_Revenue_Per_Dev(all_devs.id, '2022-11-13 MST'::timestamp);
		Pay_Month := date_trunc('month', (month_year));
		return next;
	end loop;
end;
$$


select * from generate_base_sub_rev_report('2022-11-13 MST'::timestamp)


/* developer|payout|pay_month              |
---------+------+-----------------------+
Valve    | $3.62|2022-11-01 00:00:00.000|
Sega     | $7.23|2022-11-01 00:00:00.000| */

Function: create or replace function Feature_Pack_Revenue_Per_Dev(dev_id int, month_year timestamp, fp_id int)
returns money
language plpgsql as 
$$
declare 
	payPeriodUpperBound timestamp := date_trunc('month', (month_year));
    payPeriodLowerBound timestamp := date_trunc('month', (month_year + interval '1 month'));
   	devsum int;
   	allFPGameCount float := 0; 
   	devFPGameCount float := 0; 
   	FPSubRev money := 0; 
   	targetId int := dev_id;
begin 
	select count(g.id)
	into devFpGameCount
	from featurepack f  inner join 
	game g on(f.id = g.featurepackid and (targetId = g.dev_id)) inner join 
	gameplay_record gr on (g.id = gr.gameid and (
							gr.starttime > payPeriodUpperBound) and (
							gr.starttime < payPeriodLowerBound )  );
raise notice 'devFPGames is %', devFpGameCount;			
	select count(g.id)
	into allFpGameCount
	from featurepack f  inner join 
	game g on(f.id = g.featurepackid) inner join 
	gameplay_record gr on (g.id = gr.gameid and (
							gr.starttime > payPeriodUpperBound) and (
							gr.starttime < payPeriodLowerBound )  );
						raise notice 'allFPGames is %', allFpGameCount;	
	select sum(csf.feature_sub)
	into FPSubRev
	from featurepack f inner join 
	cust_sub_featurepk csf  on(f.id = csf.featpkid and (
							csf.date_sub  > payPeriodUpperBound) and (
							csf.date_sub < payPeriodLowerBound ));
							raise notice 'baseSubRev is %', FPSubRev;
					raise notice 'baseSubRev is %', ( .1 *FPSubRev);			
	return ((devFPGameCount/allFPGameCount) * (.1 * FPSubRev));
end;
$$
select Feature_Pack_Revenue_Per_Dev(2, '2022-11-13 MST'::timestamp, 2)
```
# Report for feature packs and devs 
```sql 
create or replace function Feature_Pack_Revenue_Per_Dev(dev_id int, month_year timestamp, fp_id int)
returns money
language plpgsql as 
$$
declare 
	payPeriodUpperBound timestamp := date_trunc('month', (month_year));
    payPeriodLowerBound timestamp := date_trunc('month', (month_year + interval '1 month'));
   	devsum int;
   	allFPGameCount float := 0; 
   	devFPGameCount float := 0; 
   	FPSubRev money := 0; 
   	targetId int := dev_id;
begin 
	select count(g.id)
	into devFpGameCount
	from featurepack f  inner join 
	game_feat g_f on(f.id = fp_id) inner join 
	game g on(g_f.game_id = g.id and (targetId = g.dev_id)) inner join 
	gameplay_record gr on (g.id = gr.gameid and (
							gr.starttime > payPeriodUpperBound) and (
							gr.starttime < payPeriodLowerBound )  );
						
	select count(g.id)
	into allFpGameCount
	from featurepack f  inner join 
	game_feat g_f on (g_f.feat_id = f.id) inner join 
	game g on (g.id = g_f.game_id and public = false) inner join
	gameplay_record gr on (g.id = gr.gameid and (
							gr.starttime > payPeriodUpperBound) and (
							gr.starttime < payPeriodLowerBound )  );
	select sum(csfph.amt)
	into FPSubRev
	from featurepack f inner join 
	cust_sub_featurepk csf  on(f.id = csf.featpkid ) inner join 
	cust_sub_feat_pay_hist csfph on(csf.id = csfph.id and (
							csfph.pay_date  > payPeriodUpperBound) and (
							csfph.pay_date < payPeriodLowerBound ))
	
	;			
	return ((devFPGameCount/allFPGameCount) * (.1 * FPSubRev));
end;
$$

select Feature_Pack_Revenue_Per_Dev(2, '2022-11-13 MST'::timestamp, 2)



create or replace function  generate_feature_pack_sub_rev_report(month_year timestamp)
returns table (
	FeaturePack text,
	dev_name text,
	payout money,
	Pay_Month timestamp, 
	acitve bool
)
language plpgsql as 
$$
declare 
	all_feature_packs record; 
	all_devs record;
begin 
	for all_devs in( 
	select id, developername
	from developer
	)
	loop 
		for all_feature_packs in(
		select id, active, pack_name from featurepack
		)
		loop
			dev_name := all_devs.developername;
			FeaturePack := all_feature_packs.pack_name;
			payout := Feature_Pack_Revenue_Per_Dev(all_devs.id,month_year , all_feature_packs.id);
			Pay_Month := date_trunc('month', (month_year));
			acitve := all_feature_packs.active;
			return next;
		end loop;
	end loop;
end;
$$


select * from generate_feature_pack_sub_rev_report('2022-11-13 MST'::timestamp)

/* featurepack|dev_name|payout|pay_month              |acitve|
-----------+--------+------+-----------------------+------+
Retro      |Valve   | $0.00|2022-11-01 00:00:00.000|true  |
Sci-fi     |Valve   | $0.00|2022-11-01 00:00:00.000|true  |
Retro      |Sega    | $2.50|2022-11-01 00:00:00.000|true  |
Sci-fi     |Sega    | $2.50|2022-11-01 00:00:00.000|true  | */
```

