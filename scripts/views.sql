
set role jss;
create view jss_wfa_grade_view(grade) as
SELECT 'Normal'::text AS grade
UNION
SELECT 'Moderately Underweight'::text AS grade
UNION
SELECT 'Severely Underweight'::text AS grade;

alter table jss_wfa_grade_view owner to jss;


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
