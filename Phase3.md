# Phase  3

- 2 Chains (2x14=28pts)
    - Chain 1 cust_sub_pay_hist
    - Chain 2 cust_sub_feat_pay_hist
    - 2pt - chain easily identified {don't make it confusing - keep it easy to grade}
    - Procedure that inserts rows for entire chain
    - 2pts - each step is easily identified 
    - 10pts - chain produces 500,000+ rows
- 2+ views  (2x5pts=10pts) The two report. 
    - 2pts - appropriate name
    - 2pts - sql syntax is correct
    - 1pt - call & output provided

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

- 2+ plpgsql functions (2x5pts=10pts) Game_playable(returns bool) Can_login(returns bool)
    - 2pts - appropriate name, appropriate return type
    - 2pts - sql syntax is correct
    - 1pt - call & output provided
    game_playable() takes a game id and a customer id
    select game_playable(8,3)
    game_playable|
    -------------+
    true         |
    select game_playable(8,9)
    game_playable|
    -------------+
    false        |


    select can_login(8) Takes a customer id
    can_login|
    ---------+
    false    |
- 2+ plpgsql procedures(2x5pts=10pts) Simulate_Game_Play Renewing_subscription 
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