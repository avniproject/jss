begin;
set role jss;

insert into gender(uuid, name, version, audit_id, organisation_id)
select uuid, name, version, (create_audit((select id from users where username = 'adminjss'::text))), 11
from gender
where organisation_id = 1;

insert into subject_type(uuid, name, organisation_id, audit_id, type, version)
select uuid,
       name,
       11,
       (create_audit((select id from users where username = 'adminjss'::text))),
       type,
       version
from subject_type
where organisation_id = 1;

with audits as (update operational_subject_type ost
    set subject_type_id = st.id
    from subject_type st
    where st.organisation_id <> 1 and
          st.name = ost.name and
          st.name = 'Individual'
    returning ost.audit_id
)
update audit
set last_modified_date_time = current_timestamp
where id = (select audit_id from audits);

with audits as (
    update group_role
        set member_subject_type_id =
                (select id from subject_type where name = 'Individual' and subject_type.organisation_id = 11)
        where member_subject_type_id = 1
        returning audit_id
)
update audit
set last_modified_date_time= current_timestamp
where id in (select audit_id from audits);

insert into program(uuid, name, version, colour, organisation_id, audit_id, active)
values ('352d906c-b386-496c-ba23-91b1468a5613',
        'Child',
        0,
        'darkorange',
        11,
        (create_audit((select id from users where username = 'adminjss'::text))),
        true);

with audits as (
    update operational_program op
        set program_id = (select id from program where name = 'Child' and program.organisation_id <> 1)
        where name = 'Phulwari'
        returning audit_id)
update audit
set last_modified_date_time = current_timestamp
where id = (select audit_id from audits);

insert into encounter_type(name, uuid, version, organisation_id, audit_id, active)
select name, uuid, version, 11, (create_audit((select id from users where username = 'adminjss'::text))), true
from encounter_type
where id = 20;

with audits as (
    update operational_encounter_type oet set encounter_type_id = (select id
                                                                   from encounter_type
                                                                   where name = 'Anthropometry Assessment'
                                                                     and encounter_type.organisation_id <> 1)
        where oet.name = 'Growth Monitoring'
        returning audit_id
)
update audit
set last_modified_date_time = current_timestamp
where id = (select audit_id from audits);

with form_insertion(form_name, form_id, organisation_id) as (
    insert into form (name, form_type, uuid, version, organisation_id, audit_id)
        select name,
               form_type,
               uuid,
               version,
               11,
               (create_audit((select id from users where username = 'adminjss'::text)))
        from form
        where id in (10, 26, 8, 28)
        returning name, id, organisation_id
),
     form_element_group_insertion(feg_name, feg_id, organisation_id) as (
         insert into form_element_group (name, form_id, uuid, version, display_order, display, organisation_id,
                                         audit_id)
             select feg.name,
                    (select fi.form_id from form_insertion fi where form_name = f.name),
                    feg.uuid,
                    feg.version,
                    feg.display_order,
                    feg.display,
                    11,
                    (create_audit((select id from users where username = 'adminjss'::text)))
             from form_element_group feg
                      join form f on feg.form_id = f.id
             where f.id in (10, 26, 8, 28)
               and feg.organisation_id = 1
             returning name, id, 11
     ),
     form_element_insertion(concept_id, organisation_id) as (
         insert into form_element (name, display_order, is_mandatory, key_values, concept_id, form_element_group_id,
                                   uuid, version, organisation_id, type, valid_format_regex,
                                   valid_format_description_key, audit_id, is_voided, rule)
             select fe.name,
                    fe.display_order,
                    fe.is_mandatory,
                    fe.key_values,
                    fe.concept_id,
                    (select feg_id from form_element_group_insertion where g.name = feg_name),
                    fe.uuid,
                    fe.version,
                    11,
                    fe.type,
                    fe.valid_format_regex,
                    fe.valid_format_description_key,
                    (create_audit((select id from users where username = 'adminjss'::text))),
                    fe.is_voided,
                    fe.rule
             from form_element fe
                      join form_element_group g on fe.form_element_group_id = g.id
                      join form f2 on g.form_id = f2.id
             where f2.id in (10, 26, 8, 28)
               and fe.organisation_id = 1
             returning concept_id, 11
     )
select 1;

with form_mapping_insertion as (
    insert into form_mapping (form_id, uuid, version, entity_id, observations_type_entity_id, organisation_id,
                              audit_id, subject_type_id, enable_approval)
        select (select id from form where form.name = f4.name and form.organisation_id = 11),
               fm.uuid,
               fm.version,
               (select id from program where name = 'Child' and program.organisation_id = 11),
               case
                   when fm.observations_type_entity_id isnull then null
                   else (select id
                         from encounter_type
                         where name = 'Anthropometry Assessment'
                           and encounter_type.organisation_id = 11) end,
               11,
               (create_audit((select id from users where username = 'adminjss'::text))),
               (select id from subject_type where name = 'Individual' and subject_type.organisation_id = 11),
               fm.enable_approval
        from form_mapping fm
                 join form f4 on fm.form_id = f4.id
        where not fm.is_voided
          and f4.id in (10, 26, 8, 28)
          and entity_id = 2
          and (observations_type_entity_id isnull or observations_type_entity_id = 20)
          and fm.organisation_id = 1
),
     fm_audits as (
         update form_mapping
             set entity_id = case
                                 when entity_id isnull then null
                                 else
                                     (select id from program where name = 'Child' and program.organisation_id = 11) end,
                 observations_type_entity_id = case
                                                   when observations_type_entity_id = 20 then
                                                       (select id
                                                        from encounter_type
                                                        where name = 'Anthropometry Assessment'
                                                          and encounter_type.organisation_id = 11)
                                                   else observations_type_entity_id end,
                 subject_type_id =
                         (select id from subject_type where name = 'Individual' and subject_type.organisation_id = 11),
                 form_id = case
                               when form_id = 28 then (select id
                                                       from form
                                                       where name = 'Default Program Encounter Cancellation Form'
                                                         and form.organisation_id = 11)
                               else form_id end
             where organisation_id = 11
                 and subject_type_id = 1
             returning audit_id
     )
update audit
set last_modified_date_time = current_timestamp + id * interval '1 millisecond'
where id in (select audit_id from fm_audits);


with form_element_concept_insertion(concept_id, concept_name, organisation_id) as (
    insert into concept (data_type, high_absolute, high_normal, low_absolute, low_normal, name, uuid, version,
                         unit, organisation_id, is_voided, audit_id, key_values, active)
        select distinct on (c.name) data_type,
                                    high_absolute,
                                    high_normal,
                                    low_absolute,
                                    low_normal,
                                    c.name,
                                    c.uuid,
                                    c.version,
                                    c.unit,
                                    11,
                                    c.is_voided,
                                    (create_audit((select id from users where username = 'adminjss'::text))),
                                    c.key_values,
                                    c.active
        from concept c
                 join form_element e on c.id = e.concept_id
        where e.organisation_id = 11
          and c.organisation_id = 1
        returning id , name, organisation_id
),
     answer_concept_concept_insertion(concept_id, concept_name, organisation_id) as (
         insert into concept (data_type, high_absolute, high_normal, low_absolute, low_normal, name, uuid, version,
                              unit, organisation_id, is_voided, audit_id, key_values, active)
             select distinct on (ac.name) ac.data_type,
                                          ac.high_absolute,
                                          ac.high_normal,
                                          ac.low_absolute,
                                          ac.low_normal,
                                          ac.name,
                                          ac.uuid,
                                          ac.version,
                                          ac.unit,
                                          11,
                                          ac.is_voided,
                                          (create_audit((select id from users where username = 'adminjss'::text))),
                                          ac.key_values,
                                          ac.active
             from concept_answer ca
                      join concept c on ca.concept_id = c.id
                      join concept ac on ca.answer_concept_id = ac.id
                      join form_element e on c.id = e.concept_id
             where e.organisation_id = 11
               and ac.organisation_id = 1
             returning id , name, organisation_id
     ),
     update_form_element_concepts as (
         update form_element fe set concept_id = ci.concept_id
             from form_element_concept_insertion ci
                 join concept c on c.name = ci.concept_name
             where c.id = fe.concept_id
                 and fe.organisation_id = 11
     )
select 'Concept updated';

with insert_concept_answers(organisation_id) as (
    insert into concept_answer (concept_id, answer_concept_id, uuid, version, answer_order, organisation_id,
                                abnormal, is_voided, uniq, audit_id)
        select (select id from concept where concept.name = c.name and concept.organisation_id = 11),
               (select id from concept where concept.name = ac.name and concept.organisation_id = 11),
               ca.uuid,
               ca.version,
               ca.answer_order,
               11,
               ca.abnormal,
               ca.is_voided,
               ca.uniq,
               (create_audit((select id from users where username = 'adminjss'::text)))
        from concept_answer ca
                 join concept c on ca.concept_id = c.id
                 join concept ac on ca.answer_concept_id = ac.id
                 join form_element e on c.id = e.concept_id
        where e.organisation_id = 11
          and ca.organisation_id = 1
        returning 11
),
     decision_concept_insertion as (
         insert
             into concept (data_type, high_absolute, high_normal, low_absolute, low_normal, name, uuid, version,
                           unit, organisation_id, is_voided, audit_id, key_values, active)
                 select data_type,
                        high_absolute,
                        high_normal,
                        low_absolute,
                        low_normal,
                        name,
                        uuid,
                        version,
                        unit,
                        11,
                        is_voided,
                        (create_audit((select id from users where username = 'adminjss'::text))),
                        key_values,
                        active
                 from concept
                 where name in (
                                'Weight for age z-score',
                                'Weight for age Grade',
                                'Weight for age Status',
                                'Height for age z-score',
                                'Height for age Grade',
                                'Height for age Status',
                                'Weight for height z-score',
                                'Weight for Height Status',
                                'Growth Faltering Status',
                                'Normal',
                                'Moderately Underweight',
                                'Severely Underweight',
                                'Stunted',
                                'Severely stunted',
                                'Severely wasted',
                                'Wasted',
                                'Possible risk of overweight',
                                'Overweight',
                                'Obese',
                                'Underweight'
                     )
     )
select 'Decision concept and concept ans updated';

--add decision concept_answers
insert into concept_answer (concept_id, answer_concept_id, uuid, version, answer_order, organisation_id,
                            abnormal, is_voided, uniq, audit_id)
select (select id from concept where concept.name = c.name and concept.organisation_id = 11),
       (select id from concept where concept.name = ac.name and concept.organisation_id = 11),
       ca.uuid,
       ca.version,
       ca.answer_order,
       11,
       ca.abnormal,
       ca.is_voided,
       ca.uniq,
       (create_audit((select id from users where username = 'adminjss'::text)))
from concept_answer ca
         join concept c on ca.concept_id = c.id
         join concept ac on ca.answer_concept_id = ac.id
where ca.organisation_id = 1
  and c.name in (
                 'Weight for age Status',
                 'Height for age Status',
                 'Weight for Height Status',
                 'Growth Faltering Status'
    );

with update_concept_answer_audits as (
    update concept_answer ca set
        concept_id = (select id
                      from concept
                      where concept.name = c.name
                        and concept.organisation_id = 11),
        answer_concept_id = (select id
                             from concept
                             where concept.name = ac.name
                               and concept.organisation_id = 11)
        from concept_answer a
            join concept c on c.id = a.concept_id
            join concept ac on ac.id = a.answer_concept_id
        where ca.id = a.id
            and (ac.organisation_id = 1 or c.organisation_id = 1)
            and ca.organisation_id = 11
        returning ca.audit_id
),
     audit_updates as (
         update audit set last_modified_date_time = current_timestamp + id * interval '1 millisecond' where id in (select audit_id from update_concept_answer_audits)
     )
select 1;

--update form element
with audits as (
    update form_element fe set concept_id =
            (select id from concept where concept.name = c.name and concept.organisation_id = 11)
        from concept c
        where c.id = fe.concept_id
            and fe.organisation_id = 11 and c.organisation_id = 1
        returning fe.audit_id
)
update audit
set last_modified_date_time = current_timestamp
where id in (select audit_id from audits);

--update FEG
with audits as (
    update form_element fe
        set form_element_group_id = (select id
                                     from form_element_group
                                     where form_element_group.name = feg.name
                                       and form_element_group.organisation_id = 11)
        from form_element_group feg
        where feg.id = fe.form_element_group_id
            and fe.organisation_id = 11
            and feg.organisation_id = 1
        returning fe.audit_id
)
update audit
set last_modified_date_time = current_timestamp
where id in (
    select audit_id
    from audits
);

with audits as (
    update group_privilege
        set subject_type_id = (select id
                               from subject_type
                               where subject_type.name = (select name from subject_type where id = subject_type_id)
                                 and subject_type.organisation_id = 11),
            program_id = (select id
                          from program
                          where program.name = (select name from program where program.id = program_id)
                            and program.organisation_id = 11),
            program_encounter_type_id = (select id
                                         from encounter_type
                                         where encounter_type.name =
                                               (select name
                                                from encounter_type
                                                where encounter_type.id = program_encounter_type_id)
                                           and encounter_type.organisation_id = 11)
        where organisation_id = 11
        returning audit_id
)
update audit
set last_modified_date_time = current_timestamp
where id in (
    select audit_id
    from audits
);

update organisation
set parent_organisation_id = null
where name = 'JSS';


--------------------------------------------------------------------------------------------------------------------------
--Tests
select *
from organisation;

select *
from form_element fe
         join concept c on c.id = fe.concept_id
where fe.organisation_id = 11
  and c.organisation_id = 1;

select *
from concept
where name = 'Is baby exclusively breastfeeding'
  and organisation_id = 11;

select *
from form_element fe
         left join form_element_group feg on feg.id = fe.form_element_group_id
where fe.organisation_id = 11
  and feg.organisation_id = 1;

select f.id, feg.id, fe.id, c.id
from form f
         left join form_element_group feg on f.id = feg.form_id
         left join form_element fe on feg.id = fe.form_element_group_id
         left join concept c on fe.concept_id = c.id
order by 1;

select ca.id, c.id, ac.id
from concept_answer ca
         left join concept c on ca.concept_id = c.id
         left join concept ac on ca.answer_concept_id = ac.id;

select *
from form_mapping;

commit;
