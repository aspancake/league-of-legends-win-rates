-- Once data has been imported into PostgreSQL 

create table final_table (duration numeric, champ numeric, outcome numeric, match_id numeric);

insert into final_table
select * from c_1_18 union all 
select * from c_2_18 union all
select * from m_1_18 union all
select * from m_2_18 union all
select * from m_3_18 union all
select * from m_4_18 union all
select * from m_5_18 union all
select * from m_6_18 union all
select * from m_7_18;

create table merged_18 (duration numeric(8), champ numeric(10), outcome numeric(2), match_id numeric(14));

insert into merged_18
select distinct duration, champ, outcome, match_id
from final_table;

drop table final_table;

-- Lets see if we can convert time

alter table merged_18
add time numeric;

update merged_18
set time=(duration/60);


-- Round it off
update merged_18
set time=round(time,1);

-- Get rid of the original values

alter table merged_18
drop duration;

-- Adding values by time 

alter table merged_18
add time_group numeric;

-- Getting rid of troll matches

delete from merged_18
where time < 10;

-- Grouping
update merged_18
set time_group =
	(
	CASE WHEN (TIME < 21) THEN 1
	 WHEN ((TIME > 21) AND (Time <=27)) THEN 2
	 WHEN (time between 27 and 31) THEN 3
	 WHEN (time between 31 and 36) THEN 4 
	 WHEN (time between 36 and 47) THEN 5
	ELSE 5
	END
	);
	

