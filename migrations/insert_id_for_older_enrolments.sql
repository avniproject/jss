--migrate IDs for older enrolments
--Concept name "Enrolment ID"
--Concept UUID bdc60d4a-3c3f-4300-ab52-544252d41c1b
--Card link https://app.zenhub.com/workspaces/avni-5cf8e458bf08585333fd64ac/issues/avniproject/jss/39

set role jss;

with ids as (
    select 'DI0' || row_number() over (order by enl.id) + 100 as enrolment_number, enl.id as enl_id
    from program_enrolment enl
             join individual i on enl.individual_id = i.id
    where not i.is_voided
      and not enl.is_voided
),
     audits as (
         update program_enrolment enl set observations =
                     enl.observations || jsonb_build_object('bdc60d4a-3c3f-4300-ab52-544252d41c1b', enrolment_number)
             from ids
             where ids.enl_id = enl.id
             returning enl.audit_id
     )
update audit
set last_modified_date_time = current_timestamp + id * interval '1 millisecond'
where id in (
    select audit_id
    from audits
);

select observations ->> 'bdc60d4a-3c3f-4300-ab52-544252d41c1b'
from program_enrolment
where observations ->> 'bdc60d4a-3c3f-4300-ab52-544252d41c1b' notnull;
