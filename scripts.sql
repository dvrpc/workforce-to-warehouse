broad and state: stop_id = 43422 with feed_id=1


select * from trips a
inner join stop_times b
on a.trip_id=b.trip_id
where b.stop_id='43422';

select * from trips a
inner join stop_times b
on a.trip_id=b.trip_id
inner join calendar c
on b.service_id=c.service_id
where b.stop_id='43422'
and c.sunday=true;

-- prep stops by adding geom based on xy
ALTER TABLE stops ADD COLUMN geom geometry(Point, 4326);
UPDATE stops SET geom = ST_SetSRID(ST_MakePoint(stop_lon, stop_lat), 4326;


--install uuid extension to make unique id, necessary for looking at views in qgis
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

--select stops that are accessible from original stop
create or replace view mystops as 
with 
	mystops as (
		select 
			a.feed_id,
			a.stop_id, 
			b.trip_id, 
			b.arrival_time, 
			b.departure_time,
			c.service_id,
			c.route_id,
			a.geom
		from stops a
		inner join stop_times b
		on a.stop_id=b.stop_id
		inner join trips c
		on b.trip_id=c.trip_id
		where c.service_id='2' -- represents 7/14/2024 in njt gtfs
		and a.feed_id=1
		order by a.stop_id asc, b.arrival_time asc
	),
	myroutes as (
		select route_id as route_id_trips from trips a
		inner join stop_times b
		on a.trip_id=b.trip_id
		where b.stop_id='43422'
		and b.feed_id=1
		group by route_id
	)
select uuid_generate_v4() AS st_id, a.stop_id, a.geom from mystops a
inner join myroutes b
on a.route_id=b.route_id_trips
where a.arrival_time > '20:00:00'::time
group by stop_id, geom
order by stop_id asc;

