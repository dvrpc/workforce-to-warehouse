create or replace view mytrips as
with mytrip as (
    select 
        b.feed_id, 
        a.trip_id, 
        c.date
    from trips a
    inner join stop_times b
    on a.trip_id=b.trip_id
    inner join calendar_dates c
    on a.service_id=c.service_id
    where b.stop_id='43422'
    and b.arrival_time BETWEEN '8:00:00' and '10:00:00'
    and c.date='2024-07-13'
)
select 
    uuid_generate_v4() AS st_id, 
    c.stop_id, 
    c.geom 
from mytrip a
inner join stop_times b
on a.trip_id=b.trip_id
inner join stops c
on concat(b.stop_id,b.feed_id::varchar) = concat(c.stop_id, c.feed_id::varchar); -- avoid selecting stops with same id across agencies
