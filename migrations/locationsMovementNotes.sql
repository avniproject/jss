
select a.*
from address_level a
       join (select title, level, count(id) from address_level group by 1, 2 having count(id) > 1) as t
         on a.title = t.title
where organisation_id = (select id from organisation where db_user = 'jscs');
;
with pairs as (select title, level, count(id) from address_level group by 1, 2 having count(id) > 1),
     mapping as (select dup.id jscs, ori.id jss
                 from pairs as t
                        join address_level dup on dup.title = t.title
                        join address_level ori on ori.title = t.title
                 where dup.organisation_id = (select id from organisation where db_user = 'jscs')
                   and ori.organisation_id = (select id from organisation where db_user = 'jss'))

select cat.addresslevel_id, mapping.jss
from catchment_address_mapping cat
       join mapping on mapping.jscs = cat.addresslevel_id;
;
with pairs as (select title, level, count(id) from address_level group by 1, 2 having count(id) > 1),
     mapping as (select dup.id jscs, ori.id jss
                 from pairs as t
                        join address_level dup on dup.title = t.title
                        join address_level ori on ori.title = t.title
                 where dup.organisation_id = (select id from organisation where db_user = 'jscs')
                   and ori.organisation_id = (select id from organisation where db_user = 'jss'))

update individual i
set address_id = mapping.jss
from mapping
where mapping.jscs = i.address_id;
;
with pairs as (select title, level, count(id) from address_level group by 1, 2 having count(id) > 1),
     mapping as (select dup.id jscs, ori.id jss
                 from pairs as t
                        join address_level dup on dup.title = t.title
                        join address_level ori on ori.title = t.title
                 where dup.organisation_id = (select id from organisation where db_user = 'jscs')
                   and ori.organisation_id = (select id from organisation where db_user = 'jss'))

update location_location_mapping i
set location_id = mapping.jss
from mapping
where mapping.jscs = i.location_id;
;
with pairs as (select title, level, count(id) from address_level group by 1, 2 having count(id) > 1),
    mapping as (select dup.id jscs, ori.id jss
                from pairs as t
                       join address_level dup on dup.title = t.title
                       join address_level ori on ori.title = t.title
                where dup.organisation_id = (select id from organisation where db_user = 'jscs')
                  and ori.organisation_id = (select id from organisation where db_user = 'jss'))
delete from address_level where id in (select jscs from mapping);
;
with updates as (
  update address_level
  set organisation_id = (select id
                         from organisation
                         where db_user = 'openchs') where organisation_id in
                                                          (select id from organisation where db_user in ('jss', 'jscs'))
  returning audit_id
)
update audit a
set last_modified_date_time = current_timestamp + id * ('1 millisecond' :: interval), last_modified_by_id = 1, created_by_id = 1
from updates
where updates.audit_id = a.id;
