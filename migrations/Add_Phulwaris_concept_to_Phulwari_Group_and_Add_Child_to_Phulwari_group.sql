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

--Script to move observation from Phulwaris concept to Phulwari Group concept.

-- Preview the json
select jsonb_build_object('3fd6a9b4-6698-4206-86e6-1c74d190dda5',
                          (select uuid
                           from individual phulwari
                           where phulwari.first_name = single_select_coded(
                                   enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b')
                             and phulwari.address_id = child.address_id
                             and phulwari.subject_type_id =
                                 (select id from subject_type where name = 'Phulwari'))
           )
from individual child
         join program_enrolment enl on enl.individual_id = child.id
where child.id = enl.individual_id
  and enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b' notnull;

---MIGRATION SCRIPT-------
--Migrate the obs
with audits as (
    update program_enrolment enl
        set observations = enl.observations ||
                           jsonb_build_object('3fd6a9b4-6698-4206-86e6-1c74d190dda5',
                                              (select uuid
                                               from individual phulwari
                                               where phulwari.first_name = single_select_coded(
                                                       enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b')
                                                 and phulwari.address_id = child.address_id
                                                 and phulwari.subject_type_id =
                                                     (select id from subject_type where name = 'Phulwari'))
                               )
        from individual child
        where child.id = enl.individual_id
            and enl.observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b' notnull
        returning enl.audit_id
)
update audit
set last_modified_date_time = current_timestamp
where id in (select audit_id from audits);

--Next we need to add children to their respective phulwari group

-- these many entries(members) will be done in the group subject table
select count(*)
from program_enrolment
where observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b' notnull
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
where program_id = (select id from program where name = 'Child')
  and child.subject_type_id = (select id from subject_type where name = 'Individual')
  and phulwari.subject_type_id = (select id from subject_type where name = 'Phulwari')
  and child.id not in (select member_subject_id from group_subject where not group_subject.is_voided)
  and phulwari.address_id = child.address_id;

--Check the count there should be 0 such child now
select count(*)
from program_enrolment
where observations ->> '6129d59e-17ee-4e0d-a48d-df00b0df326b' notnull
  and individual_id not in (select member_subject_id from group_subject where not group_subject.is_voided);


