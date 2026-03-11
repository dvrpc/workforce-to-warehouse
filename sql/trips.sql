\set bbox -74.769773,40.215241,-74.751921,40.224028

-- bbox of area
drop table if exists my_bbox;
create table my_bbox as  
select st_setsrid(st_makeenvelope(:bbox),4326) as geom;

-- Specific day service table
drop table if exists day_services;
create table day_services as
with calendar_day as (
    select service_id, feed_id
    from calendar 
    where case 
        when :'day' = 'monday' then monday = true
        when :'day' = 'tuesday' then tuesday = true
        when :'day' = 'wednesday' then wednesday = true
        when :'day' = 'thursday' then thursday = true
        when :'day' = 'friday' then friday = true
        when :'day' = 'saturday' then saturday = true
        when :'day' = 'sunday' then sunday = true
    end
),
exceptions_day as (
    select service_id, feed_id, exception_type
    from calendar_dates 
    where EXTRACT(dow FROM date) = case 
        when :'day' = 'sunday' then 0
        when :'day' = 'monday' then 1
        when :'day' = 'tuesday' then 2
        when :'day' = 'wednesday' then 3
        when :'day' = 'thursday' then 4
        when :'day' = 'friday' then 5
        when :'day' = 'saturday' then 6
    end
),
all_day_services as (
    -- combine regular services
    select service_id, feed_id, 'regular' as service_type
    from calendar_day
    union
    -- add day additions (exception_type = 1)
    select service_id, feed_id, 'addition' as service_type
    from exceptions_day
    where exception_type = 1
),
filtered_services as (
    -- remove any services that have day removals (exception_type = 2)
    select a.service_id, a.feed_id
    from all_day_services a
    left join exceptions_day b
        on a.service_id = b.service_id 
        and a.feed_id = b.feed_id
        and b.exception_type = 2
    where b.service_id is null
)
select distinct service_id, feed_id
from filtered_services;

-- Origin stops in bbox
drop table if exists origin_stops;
create table origin_stops as
select a.* from stops a
inner join my_bbox b
on st_within(a.geom, b.geom);

-- Origin stops times
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

-- Get origin trips
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
inner join day_services d -- specific day service table
    on b.service_id = d.service_id
    and b.feed_id = d.feed_id
where a.feed_id=b.feed_id
and a.arrival_time >= :'starttime'
and a.arrival_time <= :'endtime';

-- Destination stop with Shift ID (A,B,C)
drop table if exists destination_stops_:shift;
create table destination_stops_:shift as
with ranked_stops as (
    select 
        a.stop_id, 
        a.feed_id,
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
    feed_id,
    arrival_time, 
    geom, 
    time_remaining
from ranked_stops
where rnk = 1;

