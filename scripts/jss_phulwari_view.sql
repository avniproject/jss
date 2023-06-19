set role jss;
create view jss_phulwari(id, address_id, uuid, first_name, last_name, gender, date_of_birth, age_in_years, age_in_months, date_of_birth_verified, registration_date, facility_id, registration_location, subject_type_id, audit_id, subject_type_name, location_name, is_voided, "Day of month for growth monitoring visit") as
WITH concepts_4654 AS (
    SELECT hstore(array_agg(c2.uuid)::text[], array_agg(c2.name)::text[]) AS map
    FROM concept
             JOIN concept_answer a_1 ON concept.id = a_1.concept_id
             JOIN concept c2 ON a_1.answer_concept_id = c2.id
    WHERE concept.uuid::text = ANY (ARRAY['6129d59e-17ee-4e0d-a48d-df00b0df326b'::character varying, '5aa2a390-764b-40cb-a601-ef520fd82d88'::character varying]::text[])
), concepts_4658 AS (
    SELECT hstore(array_agg(c2.uuid)::text[], array_agg(c2.name)::text[]) AS map
    FROM concept
             JOIN concept_answer a_1 ON concept.id = a_1.concept_id
             JOIN concept c2 ON a_1.answer_concept_id = c2.id
    WHERE concept.uuid::text = 'b4e5a662-97bf-4846-b9b7-9baeab4d89c4'::text
), concepts_decisions AS (
    SELECT hstore(array_agg(c2.uuid)::text[], array_agg(c2.name)::text[]) AS map
    FROM concept
             JOIN concept_answer a_1 ON concept.id = a_1.concept_id
             JOIN concept c2 ON a_1.answer_concept_id = c2.id
    WHERE concept.uuid::text = ''::text
)
SELECT individual.id,
       individual.address_id,
       individual.uuid,
       individual.first_name,
       individual.last_name,
       g.name AS gender,
       individual.date_of_birth,
       date_part('year'::text, age(individual.date_of_birth::timestamp with time zone)) AS age_in_years,
       date_part('year'::text, age(individual.date_of_birth::timestamp with time zone)) * 12::double precision + date_part('month'::text, age(individual.date_of_birth::timestamp with time zone)) AS age_in_months,
       individual.date_of_birth_verified,
       individual.registration_date,
       individual.facility_id,
       individual.registration_location,
       individual.subject_type_id,
       individual.audit_id,
       ost.name AS subject_type_name,
       a.title AS location_name,
       individual.is_voided,
       (individual.observations ->> '8c607c63-25fb-4af1-984e-37dd1bae653d'::text)::numeric AS "Day of month for growth monitoring visit"
FROM public.individual individual
         CROSS JOIN concepts_4654
         CROSS JOIN concepts_4658
         CROSS JOIN concepts_decisions
         LEFT JOIN operational_subject_type ost ON ost.subject_type_id = individual.subject_type_id
         LEFT JOIN gender g ON g.id = individual.gender_id
         LEFT JOIN address_level a ON individual.address_id = a.id
WHERE ost.uuid::text = 'e6c5079d-143a-4f30-87ff-77083d04d1d2'::text;

alter table jss_phulwari owner to jss;


WITH concepts_4654 AS (
    SELECT hstore(array_agg(c2.uuid)::text[], array_agg(c2.name)::text[]) AS map
    FROM concept
             JOIN concept_answer a_1 ON concept.id = a_1.concept_id
             JOIN concept c2 ON a_1.answer_concept_id = c2.id
    WHERE concept.uuid::text = ANY (ARRAY['6129d59e-17ee-4e0d-a48d-df00b0df326b'::character varying, '5aa2a390-764b-40cb-a601-ef520fd82d88'::character varying]::text[])
), concepts_4658 AS (
    SELECT hstore(array_agg(c2.uuid)::text[], array_agg(c2.name)::text[]) AS map
    FROM concept
             JOIN concept_answer a_1 ON concept.id = a_1.concept_id
             JOIN concept c2 ON a_1.answer_concept_id = c2.id
    WHERE concept.uuid::text = 'b4e5a662-97bf-4846-b9b7-9baeab4d89c4'::text
), concepts_decisions AS (
    SELECT hstore(array_agg(c2.uuid)::text[], array_agg(c2.name)::text[]) AS map
    FROM concept
             JOIN concept_answer a_1 ON concept.id = a_1.concept_id
             JOIN concept c2 ON a_1.answer_concept_id = c2.id
    WHERE concept.uuid::text = ''::text
)
SELECT individual.id,
       individual.address_id,
       individual.uuid,
       individual.first_name,
       individual.last_name,
       g.name AS gender,
       individual.date_of_birth,
       date_part('year'::text, age(individual.date_of_birth::timestamp with time zone)) AS age_in_years,
       date_part('year'::text, age(individual.date_of_birth::timestamp with time zone)) * 12::double precision + date_part('month'::text, age(individual.date_of_birth::timestamp with time zone)) AS age_in_months,
       individual.date_of_birth_verified,
       individual.registration_date,
       individual.facility_id,
       individual.registration_location,
       individual.subject_type_id,
       individual.audit_id,
       ost.name AS subject_type_name,
       a.title AS location_name,
       individual.is_voided,
       (individual.observations ->> '8c607c63-25fb-4af1-984e-37dd1bae653d'::text)::numeric AS "Day of month for growth monitoring visit"
FROM public.individual individual
         CROSS JOIN concepts_4654
         CROSS JOIN concepts_4658
         CROSS JOIN concepts_decisions
         LEFT JOIN operational_subject_type ost ON ost.subject_type_id = individual.subject_type_id
         LEFT JOIN gender g ON g.id = individual.gender_id
         LEFT JOIN address_level a ON individual.address_id = a.id
WHERE ost.uuid::text = 'e6c5079d-143a-4f30-87ff-77083d04d1d2'::text and individual.is_voided=false;
