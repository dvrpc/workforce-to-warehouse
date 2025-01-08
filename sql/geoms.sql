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


--------------------------------------------------------------------
-- SETUP FOR PGROUTING
--------------------------------------------------------------------


alter table ped_network add column if not exists source integer;
alter table ped_network add column if not exists target integer;
select pgr_createTopology('ped_network', 0.0005, 'wkb_geometry', 'objectid');
create or replace view sidewalknodes as 
    select id, st_centroid(st_collect(pt)) as geom
    from (
        (select source as id, st_startpoint(wkb_geometry) as pt
        from ped_network
        ) 
    union
        (select target as id, st_endpoint(wkb_geometry) as pt
        from ped_network
        ) 
    ) as foo
    group by id;


alter table ped_network add column if not exists length_m integer;
    update ped_network set length_m = st_length(wkb_geometry);
    alter table ped_network add column if not exists traveltime_min double precision;
    update ped_network set traveltime_min = length_m  / 4820.0 * 60; -- 4.82 kms per hr, about 3 mph. walking speed.


create index on ped_network (ogc_fid);
