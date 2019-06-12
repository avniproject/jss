ALTER TABLE address_level
  DROP CONSTRAINT lineage_parent_consistency;

-- Copy all locations from sickle-cell to phulwari with different uuids
insert into address_level (title, uuid, level, version, organisation_id, audit_id, is_voided, type_id)
select title,
       uuid_generate_v4(),
       level,
       version,
       (select id from organisation where db_user = 'jss'),
       create_audit((select id from users where username = 'adminjss')),
       is_voided,
       type_id
from address_level
where organisation_id = (select id from organisation where db_user = 'jscs');

-- For each location mapping in sickle-cell create one mapping in phulwari
-- with different uuid, child/parent location id pointing to location id of phulwari
insert into location_location_mapping (location_id, parent_location_id, version, audit_id, uuid, is_voided, organisation_id)
select
  (select c.id from address_level c where c.title = child.title and c.level=child.level and c.organisation_id = (select id from organisation where db_user = 'jss')),
  (select p.id from address_level p where p.title = parent.title and p.level=parent.level and p.organisation_id = (select id from organisation where db_user = 'jss')),
  map.version,
  create_audit((select id from users where username = 'adminjss')),
  uuid_generate_v4(),
  map.is_voided,
  (select id from organisation where db_user = 'jss')
from location_location_mapping map
       join address_level child on map.location_id = child.id
       join address_level parent on map.parent_location_id = parent.id
where map.organisation_id = (select id from organisation where db_user = 'jscs');

UPDATE address_level
SET parent_id=location_location_mapping.parent_location_id
FROM location_location_mapping
WHERE location_location_mapping.location_id=address_level.id
  and address_level.organisation_id=(select id from organisation where db_user = 'jss')
  and location_location_mapping.organisation_id=(select id from organisation where db_user = 'jss');

ALTER TABLE address_level
  ADD CONSTRAINT lineage_parent_consistency
    CHECK (
      -- only validating parent->child relationship and not the entire tree
        (parent_id IS NOT NULL AND SUBLTREE(lineage, 0, NLEVEL(lineage)) ~ CONCAT('*.', parent_id, '.', id)::lquery)
        OR
        (parent_id IS NULL AND lineage ~ CONCAT('', id)::lquery)
      );

WITH
  RECURSIVE parent_tree(id, parent_id, parents, depth) AS (
  SELECT id, parent_id, id::TEXT, 0
  FROM address_level where address_level.organisation_id=(select id from organisation where db_user = 'jss')
  UNION
  SELECT parent_tree.id, address_level.parent_id, CONCAT(address_level.id,'.',parent_tree.parents), depth+1
  FROM parent_tree
         JOIN address_level ON parent_tree.parent_id = address_level.id
),
            lineage_cte AS (SELECT DISTINCT ON (id) id, parents
                            FROM parent_tree
                            ORDER BY id, depth DESC)

UPDATE address_level
SET lineage = text2ltree(lineage_cte.parents)
FROM lineage_cte
WHERE lineage_cte.id = address_level.id;

-- Update all the phulwari individuals to point to phulwari locations instead of sickle-cell locations
with locs as (select sickle.id sickle, phulwari.id phulwari
              from address_level sickle
                     join address_level phulwari on phulwari.title=sickle.title and phulwari.level=sickle.level
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
with locs as (select sickle.id sickle, phulwari.id phulwari
              from address_level sickle
                     join address_level phulwari on phulwari.title = sickle.title and phulwari.level=sickle.level
                     join organisation sickle_o on sickle.organisation_id = sickle_o.id and sickle_o.db_user = 'jscs'
                     join organisation phulwari_o
                          on phulwari.organisation_id = phulwari_o.id and phulwari_o.db_user = 'jss')
update catchment_address_mapping set addresslevel_id = locs.phulwari
from locs where locs.sickle = addresslevel_id
            and catchment_id in
                (select id from catchment
                 where organisation_id = (select id from organisation where db_user = 'jss'));