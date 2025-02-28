SHELL = /bin/bash

include .env
export PGPASSWORD=$(PW)
export PROJ_LIB=C:\Program Files\QGIS 3.38.3\share\proj
export PSQL_CONN = -U $(PG_USER) -h $(HOST) -p $(PORT) -d $(DB)
export PG_CONN = PG:"host=$(HOST) user=$(PG_USER) password=$(PW) dbname=$(DB) port=$(PORT)"

.PHONY: gtfs costar census sidewalk geom trips walksheds access blockgroup all udrive clean

gtfs:
	gtfs2db append ./data/NJT/bus_data.zip $(DB_URI)
	gtfs2db append ./data/NJT/rail_data.zip $(DB_URI)
	gtfs2db append ./data/PATCO/PATCO.zip $(DB_URI)
	gtfs2db append ./data/SEPTA/google_bus.zip $(DB_URI)
	gtfs2db append ./data/SEPTA/google_rail.zip $(DB_URI)
	gtfs2db append ./data/Shuttles/BurlingtonShuttles_bus_data.zip $(DB_URI)
	gtfs2db append ./data/Shuttles/gmtma-nj-us.zip $(DB_URI)

costar:;
	psql $(PSQL_CONN) -v schema=public -f sql/extensions.sql
	ogr2ogr -f "PostgreSQL" $(PG_CONN) $(UDRIVE_INPUT_GPKG) -nln costar_freight_2024 -a_srs EPSG:4326 -t_srs EPSG:26918

census:
	ogr2ogr -f "PostgreSQL" PG:"host=postgres.dvrpc.org user=slawrence password=frenzy-corsage3 dbname=wrk2warehouse port=5432" "https://opendata.arcgis.com/datasets/7d313c10a6da403c8988132aa63fd140_0.geojson" -nln blockgroups -a_srs EPSG:4326 -t_srs EPSG:26918 -where "(STATEFP='10' AND COUNTYFP='001') OR (STATEFP='10' AND COUNTYFP='003') OR (STATEFP='24' AND COUNTYFP='015') OR (STATEFP='24' AND COUNTYFP='025') OR (STATEFP='34' AND COUNTYFP IN ('001','005','007','009','011','015','019','021','023','025','029','033','035','041')) OR (STATEFP='42' AND COUNTYFP IN ('011','017','029','045','071','077','091','095','101','133'))"
	python -c "from census.lodes import load_lodes_data; load_lodes_data('$(DB_URI)')"

sidewalk:
	ogr2ogr -f "PostgreSQL" $(PG_CONN) "https://opendata.arcgis.com/datasets/64a0a4c51f07471e90f948203dda71a2_0.geojson" -nln ped_network -a_srs EPSG:4326 -t_srs EPSG:26918

geom:
	psql $(PSQL_CONN) -v schema=public -f sql/geoms.sql

trips:
	psql $(PSQL_CONN) -v schema=public -v starttime='6:15:00' -v endtime='7:00:00' -v shift=a -f sql/trips.sql
	psql $(PSQL_CONN) -v schema=public -v starttime='14:15:00' -v endtime='15:00:00' -v shift=b -f sql/trips.sql
	psql $(PSQL_CONN) -v schema=public -v starttime='22:15:00' -v endtime='23:00:00' -v shift=c -f sql/trips.sql

walksheds:
	psql $(PSQL_CONN) -v schema=public -v shift=a -f sql/isochrones.sql
	psql $(PSQL_CONN) -v schema=public -v shift=b -f sql/isochrones.sql
	psql $(PSQL_CONN) -v schema=public -v shift=c -f sql/isochrones.sql

access:
	psql $(PSQL_CONN) -v schema=public -f sql/warehouse_access.sql

blockgroup:
	psql $(PSQL_CONN) -v schema=public -f sql/blockgroup_calc.sql

udrive:;
	ogr2ogr -f GPKG $(UDRIVE_OUTPUT_GPKG) \
		$(PG_CONN) -sql "select * from isoshell_a" -nln isoshell_a 
	ogr2ogr -f GPKG -append $(UDRIVE_OUTPUT_GPKG) \
		$(PG_CONN) -sql "select * from isoshell_c" -nln isoshell_b 
	ogr2ogr -f GPKG -append $(UDRIVE_OUTPUT_GPKG) \
		$(PG_CONN) -sql "select * from isoshell_c" -nln isoshell_c 
	ogr2ogr -f GPKG -append $(UDRIVE_OUTPUT_GPKG) \
		$(PG_CONN) -sql "select * from costar_freight_2024" -nln costar_with_access_type
	ogr2ogr -f GPKG -append $(UDRIVE_OUTPUT_GPKG) \
		$(PG_CONN) -sql "select * from blockgroup_data" -nln blockgroup_data

all: 
	clean gtfs costar census sidewalk geom trips walksheds access blockgroup udrive

clean:
	psql $(PSQL_CONN) -c "DROP SCHEMA public CASCADE;"
	psql $(PSQL_CONN) -c "CREATE SCHEMA public;"
	psql $(PSQL_CONN) -c "GRANT ALL ON SCHEMA public TO $(PG_USER);"
	psql $(PSQL_CONN) -c "GRANT ALL ON SCHEMA public TO public;"
	psql $(PSQL_CONN) -c "COMMENT ON SCHEMA public IS 'standard public schema';"
