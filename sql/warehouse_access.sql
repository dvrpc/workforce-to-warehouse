
------------------------------------------------------------------------------------------------------------
--- the idea here is to classify warehouses into four categories:
---   1: Warehouse accessible in all three isochrones: accessible via transit  and walking
---   2: Warehouse accessible via at least one isochrone but not all three: accessible but needs schedule 
---      adjustment
---   3: Warehouse within 1 mile of any of the three isochrones: recommendation is for sidewalk to be built 
---   4: Otherwise: warehouse needs new shuttle or transit service to be accessible
 
--- The numbers I'm setting in the warehouse_access column are equivilant to those above here.
------------------------------------------------------------------------------------------------------------



------------------------------------------------------
--- new column to classify, based on the numbers above
------------------------------------------------------
alter table costar_freight_2024
add column if not exists warehouse_access smallint,
ADD COLUMN if not exists iso_a boolean DEFAULT false,
ADD COLUMN if not exists iso_b boolean DEFAULT false,
ADD COLUMN if not exists iso_c boolean DEFAULT false;
------------------------------------------------------
--- this sets warehouses that are accessible in all three,
--- ie are accessible via transit and walking. category #1
------------------------------------------------------
update costar_freight_2024 
set warehouse_access=1 
from isoshell_a a, isoshell_b b, isoshell_c c
where st_intersects(a.geom, st_transform(costar_freight_2024.geom,26918))
and st_intersects(b.geom, st_transform(costar_freight_2024.geom,26918))
and st_intersects(c.geom, st_transform(costar_freight_2024.geom,26918));


------------------------------------------------------
--- this sets #2, places where warehouse is in at 
--- least one isochrone, but is not in all three
------------------------------------------------------
update costar_freight_2024 
set warehouse_access=2
from isoshell_a a, isoshell_b b, isoshell_c c
where 
  (st_intersects(a.geom, st_transform(costar_freight_2024.geom,26918))
  or st_intersects(b.geom, st_transform(costar_freight_2024.geom,26918))
  or st_intersects(c.geom, st_transform(costar_freight_2024.geom,26918)))
and not (
  st_intersects(a.geom, st_transform(costar_freight_2024.geom,26918))
  and st_intersects(b.geom, st_transform(costar_freight_2024.geom,26918))
  and st_intersects(c.geom, st_transform(costar_freight_2024.geom,26918))
);


------------------------------------------------------
--- create a union of all three isochrones for use 
--- creating sidewalk buffers below
------------------------------------------------------
drop table if exists iso_all;
create table if not exists iso_all as
select ST_Union(geom) as geom
from (
    select geom from isoshell_a a
    union all
    select geom from isoshell_b b
    union all
    select geom from isoshell_c c
) as combined_geoms;



------------------------------------------------------
--- buffer the iso_all table, st_difference 
--- the buffer with the iso all table to avoid overlapping
--- buffers that grab things inside iso_all. buffer is one mile
--- this represents places where <1 mile of sw could be built
--- to make the warehouse accessible.
--- potential imporvement- do on network rather than as crow flies
------------------------------------------------------

drop table if exists iso_buffer;
create table if not exists iso_buffer as
with exterior_rings as (
    select ST_ExteriorRing((ST_Dump(geom)).geom) as ering
    from iso_all
),
buffered_rings AS (
    select ST_Buffer(ering, 1609, 'side=left') as buffered_geom
    from exterior_rings
)
select st_difference(ST_Union(buffered_geom), st_collect(iso_all.geom)) as geom
from buffered_rings, iso_all;


update costar_freight_2024 
set warehouse_access=3 
from iso_buffer b
where st_within(st_transform(costar_freight_2024.geom,26918), b.geom);

------------------------------------------------------
--- Set all others to shuttle. Not technically true,
--- as you'll see all of philly as potential shuttle,
--- but this is only bc philly is outside of the 60 minute window
------------------------------------------------------
update costar_freight_2024 
set warehouse_access=4
where warehouse_access is null
or warehouse_access not in (1,2,3);

-- adds info to which iso the warehouse intersects
UPDATE costar_freight_2024 c
SET iso_a = EXISTS (
    SELECT 1 
    FROM isoshell_a a
    WHERE ST_Intersects(st_transform(c.geom,26918), a.geom)
);

UPDATE costar_freight_2024 c
SET iso_b = EXISTS (
    SELECT 1 
    FROM isoshell_b b
    WHERE ST_Intersects(st_transform(c.geom,26918), b.geom)
);

UPDATE costar_freight_2024 co
SET iso_c = EXISTS (
    SELECT 1 
    FROM isoshell_c c
    WHERE ST_Intersects(st_transform(c.geom,26918), c.geom)
);