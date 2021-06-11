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