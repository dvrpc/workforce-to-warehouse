
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
--- create a union of all three isochrones
------------------------------------------------------
drop table iso_all;
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
------------------------------------------------------

drop table iso_buffer;
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


alter table costar_freight_2024
add column if not exists warehouse_access smallint;

select st_srid(geom) from iso_buffer cf 


update costar_freight_2024 
set warehouse_access=3 
from iso_buffer b
where st_within(costar_freight_2024.geom, b.geom)
