set role jss;
with encounter_scheduled_on_enrolment_date as (
    select distinct on (pe.id) enl.id                                    enl_id,
                               concat(i.first_name, ' ', i.last_name) as name,
                               village.title                          as village,
                               enl.enrolment_date_time                as "Enrolment date time",
                               a.last_modified_date_time              as "Enrolment last modified date",
                               u.username                             as "Enrolment last modified by user",
                               earliest_visit_date_time                  "Scheduled date of scheduled encounter",
                               pe.id                                     encounter_id
    from program_enrolment enl
             join audit a on a.id = enl.audit_id
             join users u on u.id = a.last_modified_by_id
             join individual i on i.id = enl.individual_id
             join address_level village on i.address_id = village.id
             join program_encounter pe on enl.id = pe.program_enrolment_id
    where pe.earliest_visit_date_time::date = enl.enrolment_date_time::date
      and pe.encounter_date_time isnull
      and enl.program_exit_date_time isnull
      and not enl.is_voided
      and not i.is_voided
      and encounter_type_id = 20
),
     last_completed_enc as (
         select *,
                row_number() over (partition by program_enrolment_id order by encounter_date_time desc ) as row_number
         from program_encounter
         where program_enrolment_id in (
             select enl_id
             from encounter_scheduled_on_enrolment_date
         )
           and encounter_date_time notnull
           and encounter_type_id = 20
     ),
     audits as (
         update program_encounter enc
             set earliest_visit_date_time = lce.earliest_visit_date_time + '1 month'::interval
             from encounter_scheduled_on_enrolment_date d
                 join last_completed_enc lce on lce.program_enrolment_id = d.enl_id and row_number = 1
             where d.enl_id = enc.program_enrolment_id
                 and enc.id = d.encounter_id
             returning enc.audit_id
     )
update audit
set last_modified_date_time = current_timestamp + id * '1 millisecond'::interval
where id in (
    select audit_id
    from audits
);

-- select encounter_id,
--        enl.name                                           "Child name",
--        village,
--        "Enrolment date time",
--        "Enrolment last modified date",
--        "Enrolment last modified by user",
--        lce.encounter_date_time                            "Completed Date of last completed encounter",
--        lce.earliest_visit_date_time                       "Scheduled date of last completed encounter",
--        "Scheduled date of scheduled encounter",
--        lce.earliest_visit_date_time + '1 month'::interval "Correct scheduled date(to be updated)"
-- from encounter_scheduled_on_enrolment_date enl
--          join last_completed_enc lce on lce.program_enrolment_id = enl.enl_id and row_number = 1
-- order by 1
