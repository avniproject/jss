set role jss;
drop view if exists jss_wfa_grade_view;
create view jss_wfa_grade_view(grade) as
(select 'Normal'
union
select 'Moderately Underweight'
union
select 'Severely Underweight');


set role jss;
drop view if exists jss_catchment_filter;
create view jss_catchment_filter(name) as
(select id, name
from catchment
where name not like 'JSS Master Catchment');

set role jss;
drop view if exists jss_phulwari_filter;
create view jss_phulwari_filter(name) as
(select answer_concept_name as  name
from concept_concept_answer
where concept_name like 'Phulwari');

set role jss;
create view jss_visit_type(visit_type) as
SELECT 'Anthropometry Assessment'::text AS visit_type
UNION
SELECT 'Albendazole'::text AS visit_type;

alter table jss_visit_type owner to jss;

set role jss;
create view jss_visit_name(visit_name) as
SELECT 'Albendazole AUG'::text AS visit_name
UNION
SELECT 'Albendazole FEB'::text AS visit_name
UNION
SELECT 'Growth Monitoring Visit'::text AS visit_name;

alter table jss_visit_name owner to jss;
