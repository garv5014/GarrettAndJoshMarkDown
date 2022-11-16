# Key Features
- We sell subscriptions to our online services at these levels:
    - Gold ($10/month or $100/year), 5 concurrent logins
    - Silver (8/month or  $80/year), 2 concurrent logins
    - Bronze ($5/month or $50/year), 1 concurrent login
	```sql 
    select * from sub_tier;
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
    select name, featurepackid from game;
    --addtional logic to prove (elephant)
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
    --implement (elephant)
```

- Every time a user logs on to our service, 
    - we validate their account, (external autheniscation used) 
    - validate concurrent login limits
    ```sql
    -- implement (elephant)
    ```
    - log the attempt (success or failure)
    ```sql
    select id, customerid, success, timetry from log_in_out_history
    ```
- Every time the user plays a game we track it
    ```sql 
    select * from gameplay_record where (cust_subid = target)
    ```
- We can produce reports on which games get the most usage
    ```sql 
    -- double check and change (elephant)
    select g.game_name 'Game', d.developername 'Developer', sum(gr.duration) 'Time Played'
    from gameplay_record gr
    inner join game g on (g.id = gr.gameid)
    inner join developer d on (g.dev_id = d.id)
    group by 'Game', 'Developer'
    order by 'Time Played' desc; 
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
Function: create or replace procedure find_renewable()
language plpgsql 
as $$
declare
renew record;

begin 
	for renew in 
	select id, custid, subid, date_sub, exp_date, origdayofmonth, autorenew, subprice order by exp_date desc
	loop
		if(renew.autorenew and (now() - exp_date > '1 second') and (now() - exp_date < '2 months')) then
		 call renew_sub(renew);
		end if;
	end loop;

end;$$

Function: create or replace procedure renew_sub(mycustsub record)
language plpgsql 
as $$
declare
countrows int;
begin 
	countrows = count(*) from gj.cust_sub;
	INSERT INTO gj.cust_sub
	(id, custid, subid, date_sub, origdayofmonth, autorenew, sub_price)
	VALUES(countrows + 1, mycustsub.custid, mycustsub.subid, now(), record.origdayofmonth, mycustsub.autorenew, mycustsub.sub_price);
end;$$



Function: CREATE OR REPLACE FUNCTION new_sub_set_exp_date() 
	 RETURNS TRIGGER   
  LANGUAGE PLPGSQL  
  as $$  
declare 
  submonths int4;BEGIN  

	
       submonths = s.numberofmonths from gj.cust_sub cs inner join sub s on (cs.id = new.id and cs.subid = s.id);
		UPDATE gj.cust_sub
		SET exp_date=(new.date_sub + (submonths||' months')::interval)
		WHERE id=new.id;

RETURN NEW;  
END;  
$$  


CREATE TRIGGER NewSubscription  
 after insert 
 ON cust_sub 
 FOR EACH ROW  
 EXECUTE PROCEDURE new_sub_set_exp_date(); 
Note: as it turns out, adding 1 month to a date in such a case where the date goes ‘year-1-31’ defaults to the maximum number for that month.
```
## Functions for generating the report
```sql
--( DevelopersGamesPlayed/AllGamesPlayed ) * (10% of all BaseSubscription Revenue)
Function: create or replace function Base_Subscription_Revenue_Per_Dev(dev_id int, month_year timestamp)
returns money
language plpgsql as 
$$
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
		from developer as d join 
		game as g on (targetId = g.dev_id) inner join 
		gameplay_record as gr on (g.id = gr.gameid and (
									gr.starttime > payPeriodUpperBound) and (
									gr.starttime < payPeriodLowerBound )  );
		raise notice 'devGameCount is %', devGameCount;							
									
		select count(g.id)
		into allGameCount
		from game as g inner join 
		gameplay_record as gr on (g.id = gr.gameid
									and (gr.starttime > payPeriodUpperBound )
									and (gr.starttime < payPeriodLowerBound )  );
		raise notice 'allGameCount is %', allGameCount;
		select sum(cs.sub_price)
		into baseSubRev
		from cust_sub cs inner join 
		sub s on (cs.subid = s.id
					and (cs.date_sub > payPeriodUpperBound ) 
					and ( cs.date_sub < payPeriodLowerBound) 	);
						raise notice 'baseSubRev is %', baseSubRev;
					raise notice 'baseSubRev is %', ( .1 *baseSubRev);
					
	return ((devGameCount/allGameCount) * (.1 * baseSubRev));
end;
$$

-- DROP FUNCTION base_subscription_revenue_per_dev(integer,timestamp without time zone)
select Base_Subscription_Revenue_Per_Dev(1, '2022-11-13 MST'::timestamp)


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


