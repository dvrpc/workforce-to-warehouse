-- variables defined here. set a window of times you're interested in, and a day of the week, the script creates a table that has stops accessible from that bbox, at that time and day
-- bbox will grab all stops in that bbox

\set bbox -74.769773,40.215241,-74.751921,40.224028

drop table if exists my_bbox;
create table my_bbox as  
select st_setsrid(st_makeenvelope(:bbox),4326) as geom;


drop table if exists origin_stops;
create table origin_stops as
select a.* from stops a
inner join my_bbox b
on st_within(a.geom, b.geom);


drop table if exists origin_stop_times;
create table origin_stop_times as
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
from origin_stop_times a
inner join trips b
    on a.trip_id=b.trip_id
    and a.feed_id=b.feed_id
inner join line_geoms c
    on b.shape_id=c.shape_id
    and b.feed_id=c.feed_id
where a.feed_id=b.feed_id
and a.arrival_time >= :'starttime'
and a.arrival_time <= :'endtime';


drop table if exists destination_stops_:shift;
create table destination_stops_:shift as
with ranked_stops as (
    select 
        a.stop_id, 
        a.arrival_time,
        c.geom,
        (cast(:'endtime' as time) - a.arrival_time::time) as time_remaining,
        row_number() over (partition by c.geom order by a.arrival_time desc) as rnk
    from stop_times a
    inner join origin_trips b
        on a.trip_id = b.trip_id
        and a.feed_id = b.feed_id
    inner join stops c
        on a.stop_id = c.stop_id
        and a.feed_id = c.feed_id
    where a.feed_id = b.feed_id
      and a.feed_id = c.feed_id
      and a.arrival_time >= :'starttime'
      and a.arrival_time <= :'endtime'
)
select 
    stop_id, 
    arrival_time, 
    geom, 
    time_remaining
from ranked_stops
where rnk = 1;

