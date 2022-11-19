# Phase 2 turn in Josh and Garrett
## Chain 1


```sql
--Chain 1 bad data
cust_sub bad data insert testing

--cust is null
INSERT INTO public.cust_sub
(cust_id, sub_id, current_term_start, current_term_exp, date_of_origin, autorenew, active)
VALUES(null, 3, now(), now()+ '1 month'::interval, now(), false, false);

SQL Error [23502]: ERROR: null value in column "cust_id" of relation "cust_sub" violates not-null constraint
  Detail: Failing row contains (3, null, 3, 2022-11-18 16:49:58.083007, 2022-12-18 16:49:58.083007, 2022-11-18 16:49:58.083007, f, f).

--cust is out of bounds
INSERT INTO public.cust_sub
(cust_id, sub_id, current_term_start, current_term_exp, date_of_origin, autorenew, active)
VALUES(5000, 3, now(), now()+ '1 month'::interval, now(), false, false);

SQL Error [23503]: ERROR: insert or update on table "cust_sub" violates foreign key constraint "cust_sub_fk"
  Detail: Key (cust_id)=(5000) is not present in table "customer".

--sub is null
INSERT INTO public.cust_sub
(cust_id, sub_id, current_term_start, current_term_exp, date_of_origin, autorenew, active)
VALUES((3, null, now(), now()+ '1 month'::interval, now(), false, false););

SQL Error [23502]: ERROR: null value in column "sub_id" of relation "cust_sub" violates not-null constraint
  Detail: Failing row contains (5, 3, null, 2022-11-18 16:51:39.401789, 2022-12-18 16:51:39.401789, 2022-11-18 16:51:39.401789, f, f).

--sub is out of bounds
INSERT INTO public.cust_sub
(cust_id, sub_id, current_term_start, current_term_exp, date_of_origin, autorenew, active)
VALUES((3, 80, now(), now()+ '1 month'::interval, now(), false, false););

SQL Error [23503]: ERROR: insert or update on table "cust_sub" violates foreign key constraint "cust_sub_1_fk"
  Detail: Key (sub_id)=(80) is not present in table "sub".

--current term ends before it begins
INSERT INTO public.cust_sub
(cust_id, sub_id, current_term_start, current_term_exp, date_of_origin, autorenew, active)
VALUES(3, 3, now() + '1 day'::interval, now(), now()-'1 month'::interval, false, false);
--cust term begins before date of origin

SQL Error [23514]: ERROR: new row for relation "cust_sub" violates check constraint "exp_greater_then_start"
  Detail: Failing row contains (30, 3, 3, 2022-11-19 16:54:56.077846, 2022-11-18 16:54:56.077846, 2022-10-18 16:54:56.077846, f, f).

--cust term begins before date of origin
INSERT INTO public.cust_sub
(cust_id, sub_id, current_term_start, current_term_exp, date_of_origin, autorenew, active)
VALUES(3, 3, now(), now()+'1 month'::interval, now()+'1 week'::interval, false, false);
SQL Error [23514]: ERROR: new row for relation "cust_sub" violates check constraint "cust_sub_check"
  Detail: Failing row contains (23, 3, 3, 2022-11-18 17:09:15.188627, 2022-12-18 17:09:15.188627, 2022-11-25 17:09:15.188627, f, f).

--cust_subid is null
INSERT INTO public.gameplay_record
(cust_subid, gameid, starttime, duration)
VALUES(null, 3, now(), '5 minutes'::interval);

SQL Error [23502]: ERROR: null value in column "cust_subid" of relation "gameplay_record" violates not-null constraint
  Detail: Failing row contains (616, null, 3, 2022-11-18 17:14:15.13462, 00:05:00).

--cust_subid is out of bounds
INSERT INTO public.gameplay_record
(cust_subid, gameid, starttime, duration)
VALUES(3000, 3, now(), '5 minutes'::interval);

SQL Error [23503]: ERROR: insert or update on table "gameplay_record" violates foreign key constraint "gameplay_record_fk"
  Detail: Key (cust_subid)=(3000) is not present in table "cust_sub".


```

```sql
--chain 2 bad data
gameplay record bad data

--gameid is null
INSERT INTO public.gameplay_record
(cust_subid, gameid, starttime, duration)
VALUES(3, null, now(), '5 minutes'::interval);

SQL Error [23502]: ERROR: null value in column "gameid" of relation "gameplay_record" violates not-null constraint
  Detail: Failing row contains (618, 3, null, 2022-11-18 17:15:04.692221, 00:05:00).

--gameid is out of bounds
INSERT INTO public.gameplay_record
(cust_subid, gameid, starttime, duration)
VALUES(3, 3000, now(), '5 minutes'::interval);

SQL Error [23503]: ERROR: insert or update on table "gameplay_record" violates foreign key constraint "gameplay_record_fk_1"
  Detail: Key (gameid)=(3000) is not present in table "game".

```
