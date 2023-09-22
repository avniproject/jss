-- Link to the ticket - https://avni.freshdesk.com/a/tickets/3086

set role jss;


-- Below is the script to schedule Albendazole visits for all the children

with to_be_scheduled as (
	select 
	distinct pe.individual_id 	ind_id,
	pe.address_id 		add_id,
	pe.created_by_id 	cre_id,
	pe.program_enrolment_id 	program_enrolment_id 
	from individual i
	inner join program_encounter pe on i.id = pe.individual_id 
	where encounter_type_id = 42
	and i.is_voided is false
)
insert into program_encounter (
observations, encounter_date_time, encounter_type_id, individual_id, uuid,
"version", organisation_id, is_voided, audit_id, earliest_visit_date_time,
max_visit_date_time, cancel_date_time, cancel_observations, "name", created_by_id,
last_modified_by_id, created_date_time, last_modified_date_time, address_id, program_enrolment_id)
select '{}'::jsonb, null, 42, ind_id, uuid_generate_v4(),
0, 11, false, create_audit(), '2023-08-01 00:00:00.000 +0530'::timestamp,
'2023-08-30 00:00:00.000 +0530'::timestamp, null, '{}'::jsonb, 'Albendazole AUG', cre_id,
cre_id, now(), now(), add_id, program_enrolment_id
from to_be_scheduled;



-- Below is the script to cancel all the Albendazole visits that are overdue and before 1st March 2023
-- With Visit cancel reason as "Absent"
select * from encounter_type where id = 42; -- Albendazole

update program_encounter 
set cancel_date_time = now(),
cancel_observations = '{"739f9a56-c02c-4f81-927b-69842d78c1e8": "10885638-561a-42b6-8b24-8daa01864c89"}'::jsonb,
last_modified_date_time = now(),
last_modified_by_id = 5697
where organisation_id = 11
and encounter_type_id = 42
and earliest_visit_date_time::timestamp <= '2023-03-01 00:00:00.000 +0530'::timestamp
and cancel_date_time is null
and encounter_date_time is null;
-- 2677 rows affected
