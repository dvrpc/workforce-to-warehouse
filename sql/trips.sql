drop table if exists mytrips;
create table if not exists mytrips as
with mytrip as (
    select 
        a.feed_id, 
        a.trip_id, 
        c.date
    from trips a
    inner join stop_times b
    on a.trip_id=b.trip_id
    inner join calendar_dates c
    on a.service_id=c.service_id
    where b.stop_id='954'
    and b.departure_time BETWEEN '8:00:00' and '10:00:00'
    and c.date='2024-07-13'
)
select 
    a.feed_id,
    c.stop_id, 
    c.geom 
from mytrip a
inner join stop_times b
on a.trip_id=b.trip_id
inner join stops c
on b.stop_id=c.stop_id
where c.feed_id=a.feed_id
