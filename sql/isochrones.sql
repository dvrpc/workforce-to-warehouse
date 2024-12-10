select * from destination_stops;


create table isochrones as 
select 
    t1.seq, 
    t1.id1 AS Node, 
    t1.id2 AS Edge, 
    t1.cost, 
    t2.geom AS edge_geom
FROM 
PGR_DrivingDistance(
  'SELECT id, source, target, length as cost FROM sidewalks',
        (SELECT id FROM destination_stops),                                                                                   
        1000,
    false, false) t1
Left join 
    sidewalks t2
on t1.id2 = t2.id;
