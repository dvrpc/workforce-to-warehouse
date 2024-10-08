CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgrouting;

-- prep stops by adding geom based on xy
ALTER TABLE stops ADD COLUMN geom geometry(Point, 4326);
UPDATE stops SET geom = ST_SetSRID(ST_MakePoint(stop_lon, stop_lat), 4326);

