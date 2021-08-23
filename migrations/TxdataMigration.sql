set role none;

--no data in these so no migration
select *
from news;
select *
from comment_thread;
select *
from entity_approval_status;
select *
from identifier_user_assignment;
select *
from group_subject;
select *
from individual_relationship;
select *
from checklist_item;

--no migration required, returns 0
select *
from encounter e
         join encounter_type et on e.encounter_type_id = et.id
where et.organisation_id = 1
  and e.organisation_id = 11;


--entities having data
select count(*)
from program_encounter
where encounter_type_id = 20
  and organisation_id = 11;
-- 28803

--program_encounter
with ids_to_migrate as (
    select e.id                                        as encounter_id,
           encounter_type_id                           as old_id,
           (select id
            from encounter_type
            where encounter_type.name = et.name
              and encounter_type.organisation_id = 11) as new_id
    from program_encounter e
             join encounter_type et on e.encounter_type_id = et.id
    where et.organisation_id = 1
      and e.organisation_id = 11
),
     audits as (
         update program_encounter
             set encounter_type_id = new_id
             from ids_to_migrate
             where encounter_id = id
                 and encounter_type_id = old_id
             returning audit_id
     )
update audit
set last_modified_date_time = current_timestamp + id * interval '1 millisecond'
where id in (
    select audit_id
    from audits
);

--program_enrolment
select count(*)
from program_enrolment
where organisation_id = 11
group by program_id; --1997
with ids_to_migrate as (
    select enl.id                               as enrolment_id,
           program_id                           as old_id,
           (select id
            from program
            where program.name = 'Child'
              and program.organisation_id = 11) as new_id
    from program_enrolment enl
             join program p on enl.program_id = p.id
    where p.organisation_id = 1
      and enl.organisation_id = 11
),
     audits as (
         update program_enrolment
             set program_id = new_id
             from ids_to_migrate
             where enrolment_id = id
                 and program_id = old_id
             returning audit_id
     )
update audit
set last_modified_date_time = current_timestamp + id * interval '1 millisecond'
where id in (
    select audit_id
    from audits
);

--individual
select count(*), subject_type_id
from individual
where organisation_id = 11
group by subject_type_id;


with ids_to_migrate as (
    select i.id                                                                               as ind_id,
           subject_type_id                                                                    as old_id,
           (select id
            from subject_type
            where subject_type.name = 'Individual'
              and subject_type.organisation_id = 11)                                          as new_id,
           i.gender_id                                                                        as old_gender_id,
           (select id from gender where gender.name = g.name and gender.organisation_id = 11) as new_gender_id
    from individual i
             join subject_type st on i.subject_type_id = st.id
             left join gender g on i.gender_id = g.id
    where st.organisation_id = 1
      and i.organisation_id = 11
),
     audits as (
         update individual
             set subject_type_id = new_id,
                 gender_id = new_gender_id
             from ids_to_migrate
             where ind_id = id
                 and subject_type_id = old_id
                 and gender_id = old_gender_id
             returning audit_id
     )
update audit
set last_modified_date_time = current_timestamp + id * interval '1 millisecond'
where id in (
    select audit_id
    from audits
);
