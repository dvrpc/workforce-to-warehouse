drop table if exists isochrones_:shift;
create table isochrones_:shift as
with walk_time as (
    select 
        a.stop_id, 
        a.feed_id,
        b.id as node_id, 
        extract(epoch FROM a.time_remaining) / 60 as time_remaining_minutes
    from 
        destination_stops_:shift a
    join 
        sidewalknodes b 
    on
        st_dwithin(
            st_transform(a.geom, 26918),
            st_transform(b.geom, 26918),
            50) 
)
select 
    dt.stop_id,
    dt.feed_id,
    ped_network.wkb_geometry AS isochrone_geom
from 
    walk_time dt,
    lateral pgr_drivingDistance(
        'select ogc_fid as id, source, target, traveltime_min as cost from ped_network', 
        dt.node_id,                 
        dt.time_remaining_minutes,  
        false                       
    ) as dr
join 
    ped_network
on 
    dr.edge = ped_network.ogc_fid;


drop table if exists isoshell_:shift;
create table isoshell_:shift as 
with hull as (
  select stop_id, feed_id, st_concavehull(st_collect(isochrone_geom),0.1) as geom
  from isochrones_:shift 
  group by stop_id, feed_id
) 
select row_number() over() as gid, st_collectionextract(st_union(geom)) as geom from hull 
