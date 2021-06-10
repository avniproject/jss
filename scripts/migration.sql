--Script to migrate already existing children with "Disability" as "No" to "None". We have updated Disablity concept to hold different set of answers.


set role jss;
with audits as(
    update program_enrolment
set observations = observations ||
                 jsonb_build_object('100cf9ac-313d-4d20-9968-6113deecbb26',
        '["ebda5e05-a995-43ca-ad1a-30af3b937539"]'::jsonb)
where single_select_coded((observations ->> 'cbcfdd44-dac8-435f-9cd9-35f20db1f367')::text) = 'No'
    returning audit_id
    )
update audit
set last_modified_date_time = current_timestamp
where id in (select audit_id from audits);
