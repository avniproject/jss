--
-- Card : https://app.zenhub.com/workspaces/avni-5cf8e458bf08585333fd64ac/issues/avniproject/jss/54
-- Context: Earlier JSS had Phulwari coded concept and each child was mapped to a phulwari during enrolment. Now for the attendance feature
-- we have added new group subject type "Phulwari". So we'll remove this old coded concept and will use new GroupAffiliation concept
-- "Phulwari group" which will also add child to the respective phulwari group.
-- This migration is required for the old data, It'll do two things
-- 1. Add the observation for the newly added "Phulwari group" concept as per the previously answered "phulwaris" coded concept in the child enrolment enrolment,
-- 2. Add child to their respective phulwari group.
-- Assumption : All the phulwaris are registered by the user and have same name as the Phulwari concept answers.

set role jss;

--TODO: Right now some phulwaris are registered more than once in the same location. User need to void those before running the script
select first_name "Phulwari name", title "Village name", count(*)
from individual
         join address_level al on individual.address_id = al.id
where subject_type_id = (select id from subject_type where name = 'Phulwari')
  and individual.is_voided = false
group by 1, 2
order by 3 desc;

--Register the Phulwaris which they have not registered yet.
insert into individual (uuid, address_id, observations, version, registration_date, organisation_id, first_name,
                        audit_id, subject_type_id, date_of_birth_verified, is_voided)

select distinct on (enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b', child.address_id) uuid_generate_v4(),
                                                                                                   child.address_id,
                                                                                                   jsonb_build_object(
                                                                                                           '6129d59e-17ee-4e0d-a48d-df00b0df326b',
                                                                                                           enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b',
                                                                                                           '8c607c63-25fb-4af1-984e-37dd1bae653d',
                                                                                                           (enl.observations ->> '8c607c63-25fb-4af1-984e-37dd1bae653d')::numeric),
                                                                                                   0,
                                                                                                   now()::date,
                                                                                                   11,
                                                                                                   single_select_coded(
                                                                                                               enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b'),
                                                                                                   (create_audit((select id from users where username = 'adminjss'::text))),
                                                                                                   (select id from subject_type where name = 'Phulwari'),
                                                                                                   false,
                                                                                                   false
from program_enrolment enl
         join individual child on enl.individual_id = child.id
         join address_level village on village.id = child.address_id
         left join individual phulwari on phulwari.first_name = single_select_coded(
            enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b')
    and phulwari.address_id = child.address_id
where enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b' notnull
  and phulwari.id isnull
  and enl.program_exit_date_time isnull
  and not enl.is_voided
  and not child.is_voided;

--Ensure that all the phulwaris are registered. Below script should return empty
select single_select_coded(enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b') "Phulwari",
       village.title                                                                    "Village"
from program_enrolment enl
         join individual child on enl.individual_id = child.id
         join address_level village on village.id = child.address_id
         left join individual phulwari on phulwari.first_name = single_select_coded(
            enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b')
    and phulwari.address_id = child.address_id
where enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b' notnull
  and phulwari.id isnull
  and enl.program_exit_date_time isnull
  and not enl.is_voided
  and not child.is_voided;

--Script to move observation from Phulwaris concept to Phulwari Group concept.
--We don't need this migration as we don't store group concept in obs

--Next we need to add children to their respective phulwari group

-- these many entries(members) will be done in the group subject table
select count(*)
from program_enrolment enl
         join individual i on enl.individual_id = i.id
where enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b' notnull
  and program_exit_date_time isnull
  and not enl.is_voided
  and not i.is_voided
  and individual_id not in (select member_subject_id from group_subject where not group_subject.is_voided);

---MIGRATION SCRIPT-------
--Add the members to the Phulwari group
insert into group_subject(uuid, group_subject_id, member_subject_id, group_role_id, membership_start_date,
                          organisation_id, audit_id, version)
select uuid_generate_v4(),
       phulwari.id,
       child.id,
       (select gr.id from group_role gr where gr.role = 'Phulwari Child'),
       current_timestamp,
       (select id from organisation where name = 'JSS'),
       create_audit((select id from users where username = 'adminjss')),
       0
from program_enrolment enl
         join individual child on enl.individual_id = child.id
         join individual phulwari
              on phulwari.first_name = single_select_coded(enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b')
where program_id = (select id from program where name = 'Phulwari')
  and child.subject_type_id = (select id from subject_type where name = 'Individual')
  and phulwari.subject_type_id = (select id from subject_type where name = 'Phulwari')
  and child.id not in (select member_subject_id from group_subject where not group_subject.is_voided)
  and phulwari.address_id = child.address_id
  and program_exit_date_time isnull
  and not enl.is_voided
  and not child.is_voided
  and not phulwari.is_voided;

--Check the count there should be 0 such child now
select count(*)
from program_enrolment enl
         join individual i on enl.individual_id = i.id
where enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b' notnull
  and program_exit_date_time isnull
  and not enl.is_voided
  and not i.is_voided
  and individual_id not in (select member_subject_id from group_subject where not group_subject.is_voided);

