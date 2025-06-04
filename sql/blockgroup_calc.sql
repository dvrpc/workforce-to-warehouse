-- aggregates costar points to blockgroups and calcs lodes data
DROP TABLE IF EXISTS blockgroup_data;
CREATE TABLE
  blockgroup_data AS
WITH
  a AS (
    SELECT
      bg.geoid,
      COUNT(cs.geom) AS costar_count,
      bg.wkb_geometry AS geom
    FROM
      blockgroups bg
      JOIN costar_freight_2024 cs ON st_intersects (bg.wkb_geometry, st_transform(cs.geom,26918))
    GROUP BY
      bg.geoid,
      bg.wkb_geometry
  )
SELECT
  a.geoid,
  a.costar_count as warehouse_count,
  SUM(l.c000::NUMERIC) AS total_jobs,
  SUM(l.cns08::NUMERIC) AS total_trans_warehouse,
  a.geom
FROM
  a
  JOIN lodes_data l ON a.geoid = LEFT(l.w_geocode, 12)
GROUP BY
  a.geoid,
  a.costar_count,
  a.geom;

-- create masks for the isoshells using the blockgroups
DROP TABLE IF EXISTS blockgroup_unioned;
DROP TABLE IF EXISTS isoshell_a_mask;
DROP TABLE IF EXISTS isoshell_b_mask;
DROP TABLE IF EXISTS isoshell_c_mask;

CREATE TABLE
  blockgroup_unioned AS
SELECT
  st_union (bg.wkb_geometry) as geometry
FROM
  blockgroups bg;

CREATE INDEX blockgroup_union_idx on blockgroup_unioned using GIST(geometry);

CREATE TABLE
  isoshell_a_mask AS
SELECT
  st_difference (bg.geometry, st_union (a.geom)) AS geometry
FROM
  public.blockgroup_unioned bg,
  public.isoshell_a a
GROUP BY
  bg.geometry;

CREATE TABLE
  isoshell_b_mask AS
SELECT
  st_difference (bg.geometry, st_union (a.geom)) AS geometry
FROM
  public.blockgroup_unioned bg,
  public.isoshell_b a
GROUP BY
  bg.geometry;

CREATE TABLE
  isoshell_c_mask AS
SELECT
  st_difference (bg.geometry, st_union (a.geom)) AS geometry
FROM
  public.blockgroup_unioned bg,
  public.isoshell_c a
GROUP BY
  bg.geometry;