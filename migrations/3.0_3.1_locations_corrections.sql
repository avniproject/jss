
-- Copy all locations from sickle-cell to phulwari with different uuids
insert into address_level (title, uuid, level, version, organisation_id, audit_id, is_voided, type_id, lineage)
select title,
       uuid_generate_v4(),
       level,
       version,
       (select id from organisation where db_user = 'jss'),
       create_audit((select id from users where username = 'adminjss')),
       is_voided,
       type_id,
       lineage
from address_level
where organisation_id = (select id from organisation where db_user = 'jscs');

-- For each location mapping in sickle-cell create one mapping in phulwari
-- with different uuid, child/parent location id pointing to location id of phulwari
insert into location_location_mapping (location_id, parent_location_id, version, audit_id, uuid, is_voided, organisation_id)
select
       (select c.id from address_level c where c.lineage = child.lineage and c.organisation_id = (select id from organisation where db_user = 'jss')),
       (select p.id from address_level p where p.lineage = parent.lineage and p.organisation_id = (select id from organisation where db_user = 'jss')),
       map.version,
       create_audit((select id from users where username = 'adminjss')),
       uuid_generate_v4(),
       map.is_voided,
       (select id from organisation where db_user = 'jss')
from location_location_mapping map
  join address_level child on map.location_id = child.id
  join address_level parent on map.parent_location_id = parent.id
where map.organisation_id = (select id from organisation where db_user = 'jscs');

-- Update all the phulwari individuals to point to phulwari locations instead of sickle-cell locations
with locs as (select sickle.id sickle, phulwari.id phulwari, sickle.lineage
                      from address_level sickle
                      join address_level phulwari on phulwari.lineage = sickle.lineage
                      join organisation sickle_o on sickle.organisation_id = sickle_o.id and sickle_o.db_user = 'jscs'
                      join organisation phulwari_o
                       on phulwari.organisation_id = phulwari_o.id and phulwari_o.db_user = 'jss'),
      updates as (update individual
                      set address_id = locs.phulwari
                      from locs
                      where locs.sickle = individual.address_id and organisation_id = (select id from organisation where db_user='jss')
                      returning audit_id)
update audit set last_modified_date_time = current_timestamp
from updates where audit.id in (select audit_id from updates);

-- Update all the phulwari catchments to point to phulwari locations instead of sickle-cell locations
with locs as (select sickle.id sickle, phulwari.id phulwari, sickle.lineage
              from address_level sickle
                     join address_level phulwari on phulwari.lineage = sickle.lineage
                     join organisation sickle_o on sickle.organisation_id = sickle_o.id and sickle_o.db_user = 'jscs'
                     join organisation phulwari_o
                       on phulwari.organisation_id = phulwari_o.id and phulwari_o.db_user = 'jss')
update catchment_address_mapping set addresslevel_id = locs.phulwari
from locs where locs.sickle = addresslevel_id;
