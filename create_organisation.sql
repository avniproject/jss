CREATE ROLE jss
  NOINHERIT
  PASSWORD 'password';

GRANT jss TO openchs;

GRANT ALL ON ALL TABLES IN SCHEMA public TO jss;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO jss;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO jss;

INSERT INTO organisation (name, db_user, uuid, parent_organisation_id)
  SELECT
    'JSS',
    'jss',
    'a18b792b-7256-4529-896c-e5629e247cf9',
    id
  FROM organisation
  WHERE name = 'OpenCHS';
