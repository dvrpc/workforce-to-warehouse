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

clean:;
	 psql -U $(PG_USER) -p $(PORT) -d $(DB) -c "DROP SCHEMA public CASCADE;"	
	 psql -U $(PG_USER) -p $(PORT) -d $(DB) -c "CREATE SCHEMA public;"	
	 psql -U $(PG_USER) -p $(PORT) -d $(DB) -c "GRANT ALL ON SCHEMA public TO $(PG_USER);"	
	 psql -U $(PG_USER) -p $(PORT) -d $(DB) -c "GRANT ALL ON SCHEMA public TO public"	
	 psql -U $(PG_USER) -p $(PORT) -d $(DB) -c "COMMENT ON SCHEMA public IS 'standard public schema';"	

geom:;
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -f sql/geoms.sql

trips:;	
	psql -U $(PG_USER) -p $(PORT) -d $(DB) -v schema=public -f sql/trips.sql
