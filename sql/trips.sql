-- tldr: stop ids in njtransit are not unique, which is causing problems. they are for septa


drop table if exists my_bbox;
create table my_bbox as  
select st_setsrid(st_makeenvelope(-74.769773,40.215241,-74.751921,40.224028),4326) as geom;



drop table if exists origin_stops;
create table origin_stops as
select a.* from stops a
inner join my_bbox b
on st_within(a.geom, b.geom);




-- drop table if exists origin_stop_times;
-- create table origin_stop_times as
-- select 
--     a.stop_id, 
--     a.feed_id, 
--     c.trip_id,
--     c.departure_time,
--     a.geom
-- from origin_stops a
-- inner join stop_times c
-- on a.stop_id=c.stop_id
-- where a.feed_id=c.feed_id;

-- drop table if exists mytrips;
-- create table mytrips as 
-- select 
--     a.trip_id, 
--     c.geom
-- from trips a
-- inner join origin_stops b
-- on a.trip_id=b.trip_id
-- inner join line_geoms c
-- on a.shape_id=c.shape_id
-- where b.departure_time BETWEEN '8:00:00' and '10:00:00';













