
set role jss;
create view jss_wfa_grade_view(grade) as
SELECT 'Normal'::text AS grade
UNION
SELECT 'Moderately Underweight'::text AS grade
UNION
SELECT 'Severely Underweight'::text AS grade;

alter table jss_wfa_grade_view owner to jss;
