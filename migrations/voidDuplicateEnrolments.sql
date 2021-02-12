set role jss;

-- https://avni.freshdesk.com/a/tickets/1090
-- There are more than one enrolments for these subject ids we need to
-- 1. Move program encounters from other enrolments to first enrolment.
-- 2. Void other program enrolment and keep only the first one.
-- 3. update the exit date of the first enrolment with that of last enrolment.
with enrolment_numbers as (
    select id,
           row_number() over (partition by individual_id order by enrolment_date_time) enrolment_number,
           individual_id,
           program_exit_date_time
    from program_enrolment
    where individual_id in
          (154559, 317940, 43534, 44096, 44187, 44285, 44288, 44703, 44704, 44778, 44796, 44801, 44864, 44865, 45199,
           45212, 45794, 45829, 45838, 45904, 45907, 45920, 45921, 45925, 47578, 47594, 57086, 65686, 68487, 68490,
           68491, 69645, 82916, 83280, 86536, 99817, 99819
              )
),
--update the exit date of first enrolment with the exit date of last enrolment.
     enrolment_exit_audits as (
         update program_enrolment pe
             set program_exit_date_time =
                     (select program_exit_date_time
                      from enrolment_numbers en
                      where en.individual_id = pe.individual_id
                        and en.enrolment_number =
                            (select max(enrolment_number)
                             from enrolment_numbers en2
                             where en2.individual_id = pe.individual_id)
                     )
             where id in (
                 select id
                 from enrolment_numbers
                 where enrolment_number = 1
             ) returning pe.audit_id
     ),
-- void the all enrolments except the first one
     enrolment_void_audits as (
         update program_enrolment set is_voided = true where id in (
             select id
             from enrolment_numbers
             where enrolment_number > 1
         )
             returning audit_id
     ),
--move all program encounters to the first enrolment
     encounter_audits as (
         update program_encounter pe
             set program_enrolment_id = (select id
                                         from enrolment_numbers
                                         where enrolment_number = 1
                                           and individual_id = (select individual_id
                                                                from program_enrolment
                                                                where id = pe.program_enrolment_id))
             where program_enrolment_id in (
                 select id
                 from enrolment_numbers
                 where enrolment_number > 1
             )
             returning audit_id
     )
update audit
set last_modified_date_time = current_timestamp
where id in (select audit_id
             from enrolment_exit_audits
             union all
             select audit_id
             from enrolment_void_audits
             union all
             select audit_id
             from encounter_audits
);

-----TEST counts before the migration
--before running the migration it'll give first enrolment id, total program encounter and last enrolment exit date for each individual
select i.id                             individual_id,
       count(p.*)                       total_encounters,
       min(pe.id)                       first_enolment_id,
       (select program_exit_date_time
        from program_enrolment pe2
        where pe2.id = (select max(id)
                        from program_enrolment pe3
                        where pe3.individual_id = i.id
                        group by i.id)) program_exit_date_time
from individual i
         join program_enrolment pe on i.id = pe.individual_id
         join program_encounter p on pe.id = p.program_enrolment_id
where i.id in
      (154559, 317940, 43534, 44096, 44187, 44285, 44288, 44703, 44704, 44778, 44796, 44801, 44864, 44865, 45199,
       45212, 45794, 45829, 45838, 45904, 45907, 45920, 45921, 45925, 47578, 47594, 57086, 65686, 68487, 68490,
       68491, 69645, 82916, 83280, 86536, 99817, 99819
          )
group by 1;

--TEST counts after the migration
--After running the migration check the count from above script with the non voided enrolments
select i.id       individual_id,
       count(p.*) total_encounters,
       pe.id      first_enolment_id,
       pe.program_exit_date_time
from individual i
         join program_enrolment pe on i.id = pe.individual_id
         join program_encounter p on pe.id = p.program_enrolment_id
where i.id in
      (154559, 317940, 43534, 44096, 44187, 44285, 44288, 44703, 44704, 44778, 44796, 44801, 44864, 44865, 45199,
       45212, 45794, 45829, 45838, 45904, 45907, 45920, 45921, 45925, 47578, 47594, 57086, 65686, 68487, 68490,
       68491, 69645, 82916, 83280, 86536, 99817, 99819
          )
  and pe.is_voided = false
group by 1, 3;
