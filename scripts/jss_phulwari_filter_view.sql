set role jss;
create view jss_phulwari_filter(name) as
SELECT DISTINCT unnest(ARRAY [individual.first_name, concept_concept_answer.answer_concept_name]) AS name
FROM public.individual
         CROSS JOIN concept_concept_answer
WHERE individual.subject_type_id = ((SELECT subject_type.id
                                     FROM subject_type
                                     WHERE subject_type.name::text = 'Phulwari'::text))
  AND NOT individual.is_voided
  AND concept_concept_answer.concept_name::text ~~ 'Phulwari'::text;

alter table jss_phulwari_filter
    owner to jss;
