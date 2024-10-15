-- tldr: stop ids in njtransit are not unique, which is causing problems. they are for septa


drop table if exists my_bbox;
create table my_bbox as  
select st_setsrid(st_makeenvelope(-74.769773,40.215241,-74.751921,40.224028),4326) as geom;

drop table origin_stops;
create table if not exists origin_stops as
select 
    a.stop_id, 
    a.feed_id, 
    c.trip_id,
    c.departure_time,
    a.geom
from stops a
inner join my_bbox b
on st_within(a.geom, b.geom)
inner join stop_times c
on a.stop_id=c.stop_id
and a.feed_id=c.feed_id;

drop table if exists mytrips;
create table mytrips as 
select 
    a.trip_id, 
    c.geom
from trips a
inner join origin_stops b
on a.trip_id=b.trip_id
inner join line_geoms c
on a.shape_id=c.shape_id
where b.departure_time BETWEEN '8:00:00' and '10:00:00';





















-- select 
--     a.stop_id,
--     a.feed_id,
--     e.geom,
--     b.trip_id
-- from origin_stops a
-- inner join stop_times b 
-- on a.stop_id=b.stop_id
-- inner join trips c
-- on b.trip_id=c.trip_id
-- inner join calendar_dates d
-- on c.service_id=d.service_id
-- inner join line_geoms e
-- on c.shape_id=e.shape_id
-- where b.departure_time BETWEEN '8:00:00' and '10:00:00'
-- and d.date='2024-07-13'
-- and st_within(a.geom, st_setsrid(st_makeenvelope(-74.769773,40.215241,-74.751921,40.224028),4326));





-- select * from origin_stops
-- create table if not exists mytrips as
-- with mytrip as (
--     select 
--         a.feed_id, 
--         b.stop_id,
--         a.trip_id, 
--         c.date 
--     from trips a
--     inner join stop_times b
--     on a.trip_id=b.trip_id
--     inner join calendar_dates c
--     on a.service_id=c.service_id
--     where b.stop_id='43422'
--     and b.departure_time BETWEEN '8:00:00' and '10:00:00'
--     and c.date='2024-07-13'
-- )
-- select * from mytrip
