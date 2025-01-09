SHELL = /bin/bash

include .env

load:;
	gtfs2db append ./data/NJT/bus_data.zip $(DB_URI)
	gtfs2db append ./data/NJT/rail_data.zip $(DB_URI)
	gtfs2db append ./data/PATCO/PATCO.zip $(DB_URI)
	gtfs2db append ./data/SEPTA/google_bus.zip $(DB_URI)
	gtfs2db append ./data/SEPTA/google_rail.zip $(DB_URI)
	gtfs2db append ./data/Shuttles/BurlingtonShuttles_bus_data.zip $(DB_URI)
	gtfs2db append ./data/Shuttles/gmtma-nj-us.zip $(DB_URI)

	# costar data
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -f sql/extensions.sql
	ogr2ogr -f "PostgreSQL" PG:"host=localhost user=$(PG_USER) dbname=$(DB) port=$(PORT)" $(UDRIVE_INPUT_GPKG) -nln costar_freight_2024 -a_srs EPSG:4326 -t_srs EPSG:26918
sidewalk:;
	# the geojson endpoint will need to be updated after the azure migration, which is sometime in jan 2025
	ogr2ogr -f "PostgreSQL" PG:"host=localhost user=$(PG_USER) dbname=$(DB) port=$(PORT)" "https://opendata.arcgis.com/datasets/40186cee01824f11a407766e0cf32940_0.geojson" -nln ped_network -a_srs EPSG:4326 -t_srs EPSG:26918

geom:;
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -f sql/geoms.sql

trips:;	
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -v starttime='7:00:00' -v endtime='8:00:00' -v shift=a -f sql/trips.sql
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -v starttime='15:00:00' -v endtime='16:00:00' -v shift=b -f sql/trips.sql
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -v starttime='23:00:00' -v endtime='23:59:59' -v shift=c -f sql/trips.sql

walksheds:;	
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -v shift=a -f sql/isochrones.sql
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -v shift=b -f sql/isochrones.sql
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -v shift=c  -f sql/isochrones.sql

access:;
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -f sql/warehouse_access.sql

all:;
	make clean
	make load
	make sidewalk
	make geom
	make trips
	make walksheds
	make access

udrive:;
	ogr2ogr -f GPKG $(UDRIVE_OUTPUT_GPKG) \
		PG:"host=localhost user=$(PG_USER) dbname=$(DB) port=$(PORT)" \
		-sql "select * from isoshell_a" isoshell_a 
	ogr2ogr -f GPKG -append $(UDRIVE_OUTPUT_GPKG) \
		PG:"host=localhost user=$(PG_USER) dbname=$(DB) port=$(PORT)" \
		-sql "select * from isoshell_c" isoshell_b 
	ogr2ogr -f GPKG -append $(UDRIVE_OUTPUT_GPKG) \
		PG:"host=localhost user=$(PG_USER) dbname=$(DB) port=$(PORT)" \
		-sql "select * from isoshell_c" isoshell_c 
	
# Delete all 
clean:;
	 psql -U $(PG_USER) -p $(PORT) -d $(DB) -c "DROP SCHEMA public CASCADE;"	
	 psql -U $(PG_USER) -p $(PORT) -d $(DB) -c "CREATE SCHEMA public;"	
	 psql -U $(PG_USER) -p $(PORT) -d $(DB) -c "GRANT ALL ON SCHEMA public TO $(PG_USER);"	
	 psql -U $(PG_USER) -p $(PORT) -d $(DB) -c "GRANT ALL ON SCHEMA public TO public"	
	 psql -U $(PG_USER) -p $(PORT) -d $(DB) -c "COMMENT ON SCHEMA public IS 'standard public schema';"	
