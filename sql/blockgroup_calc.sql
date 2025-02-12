-- aggregates costar points to blockgroups and calcs lodes data
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
      JOIN costar_freight_2024 cs ON st_intersects (bg.wkb_geometry, cs.geom)
    GROUP BY
      bg.geoid,
      bg.wkb_geometry
  )
SELECT
  a.geoid,
  a.costar_count,
  SUM(l.c000::NUMERIC) AS total_jobs,
  SUM(l.cns05::NUMERIC) AS total_manufacturing,
  SUM(l.cns06::NUMERIC) AS total_wholesaletrade,
  SUM(l.cns07::NUMERIC) AS total_retailtrade,
  SUM(l.cns08::NUMERIC) AS total_trans_warehouse,
  a.geom
FROM
  a
  JOIN lodes_data l ON a.geoid = LEFT(l.w_geocode, 12)
GROUP BY
  a.geoid,
  a.costar_count,
  a.geom;