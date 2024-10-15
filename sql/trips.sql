-- tldr: stop ids in njtransit are not unique, which is causing problems. they are for septa


drop table if exists my_bbox;
create table my_bbox as  
select st_setsrid(st_makeenvelope(-74.769773,40.215241,-74.751921,40.224028),4326) as geom;



drop table if exists origin_stops;
create table origin_stops as
select a.* from stops a
inner join my_bbox b
on st_within(a.geom, b.geom);


drop table if exists test_stops;
create table test_stops as
select 
    a.feed_id,
    a.stop_id, 
    b.trip_id,
    b.arrival_time,
    b.departure_time,
    b.timepoint
from origin_stops a
inner join stop_times b
    on a.stop_id=b.stop_id
    and a.feed_id=b.feed_id
where a.feed_id=b.feed_id;


drop table if exists origin_trips;
create table origin_trips as
select 
    a.*,
    b.service_id, 
    b.shape_id, 
    c.geom
from test_stops a
inner join trips b
    on a.trip_id=b.trip_id
    and a.feed_id=b.feed_id
inner join line_geoms c
    on b.shape_id=c.shape_id
    and b.feed_id=c.feed_id
where a.feed_id=b.feed_id;


