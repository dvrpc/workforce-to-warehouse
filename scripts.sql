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


--select stops that are accessible from original stop
with 
	mystops as (
		select 
			a.stop_id, 
			b.trip_id, 
			b.arrival_time, 
			b.departure_time,
			c.route_id,
			a.stop_lat, 
			a.stop_lon 
		from stops a
		inner join stop_times b
		on a.stop_id=b.stop_id
		inner join trips c
		on b.trip_id=c.trip_id
		order by a.stop_id asc, b.arrival_time asc
	),
	myroutes as (
		select route_id from trips a
		inner join stop_times b
		on a.trip_id=b.trip_id
		where b.stop_id='43422'
		group by route_id
	)
select * from mystops a
inner join myroutes b
on a.route_id=b.route_id;

