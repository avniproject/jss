
DO $$
DECLARE
max_date TIMESTAMP; earliest_date TIMESTAMP; enrol record; et_id integer; org_id integer; prog_id integer;
  uid integer;
BEGIN
  select id from users where name = 'dataimporter@jss' into uid;
  select id from encounter_type where name = 'Albendazole' into et_id;
  select id from organisation where name = 'JSS' into org_id;
  select id from program where name = 'Child' into prog_id;
  earliest_date := '2019-02-08';
  max_date := '2019-02-28';

  FOR enrol IN (select id
                  from program_enrolment
                  where organisation_id = org_id
                    and is_voided is not true
                    and program_exit_date_time isnull
                    and prog_id = program_id
                    and id not in (select program_enrolment_id from program_encounter
                                   where encounter_type_id = et_id
                                     and is_voided is not true
                                     and earliest_visit_date_time notnull
                                     and organisation_id = org_id))
  LOOP
    insert into program_encounter (observations, cancel_observations, earliest_visit_date_time, max_visit_date_time, program_enrolment_id, uuid, version, encounter_type_id, name, organisation_id, audit_id)
    values ('{}'::jsonb, '{}'::jsonb, earliest_date, max_date, enrol.id, uuid_generate_v4(), 0,  et_id, 'Albendazole FEB', org_id, create_audit(uid));
  END LOOP;

END $$
LANGUAGE plpgsql;

