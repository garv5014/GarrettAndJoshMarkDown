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