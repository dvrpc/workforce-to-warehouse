CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgrouting;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- prep stops by adding geom based on xy
ALTER TABLE stops ADD COLUMN if not exists geom geometry(Point, 4326);
UPDATE stops SET geom = ST_SetSRID(ST_MakePoint(stop_lon, stop_lat), 4326);


create table if not exists line_geoms as
SELECT 
    uuid_generate_v4() as st_id,
    feed_id,
    shape_id,
    ST_MakeLine(
        ST_MakePoint(shape_pt_lon, shape_pt_lat)
        ORDER BY shape_pt_sequence
    ) AS geom
FROM shapes
GROUP BY feed_id, shape_id;

update line_geoms set geom = ST_SetSRID(geom, 4326);
