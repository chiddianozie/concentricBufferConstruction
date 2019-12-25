
-- To create the table
CREATE TABLE streetSample
(
    street text,
    osmid text,
    geom text
);

-- Create extension and spatial index on the table
CREATE EXTENSION postgis;
CREATE INDEX streetSample_index 
    ON streetSample 
    USING gist
(geom);


-- persist file contents to table
COPY streetSample
(street, osmid, geom) 
FROM '/path/to/file/on/local/streetSample.csv'  DELIMITER ',' CSV HEADER;

-- Change the SRID of the geom column
ALTER TABLE streetSample 
    ALTER COLUMN geom 
    TYPE
geometry 
    USING ST_SetSRID
((geom::geometry),4326);

-- create new columns for the buffers

ALTER TABLE streetSample  ADD COLUMN buffer_20_metres geometry
(Geometry, 4326);
ALTER TABLE streetSample  ADD COLUMN buffer_100_metres geometry
(Geometry, 4326);
ALTER TABLE streetSample  ADD COLUMN buffer_200_metres geometry
(Geometry, 4326);

-- actual creation of the buffers and write the coordinates to the column created 
UPDATE streetSample  SET buffer_20_metres = ST_Transform(ST_Buffer(ST_Transform(geom,3857), 20,  'endcap=round join=round'),4326);

UPDATE streetSample 
    SET buffer_100_metres =  
        ST_Transform(
            ST_Difference(
                ST_Buffer(ST_Transform(geom,3857), 100,  'endcap=round join=round'),
                ST_Buffer(ST_Transform(geom,3857), 20,  'endcap=round join=round')),
                4326);

UPDATE streetSample 
    SET buffer_200_metres =  
        ST_Transform(
            ST_Difference(
                ST_Buffer(ST_Transform(geom,3857), 200,  'endcap=round join=round'),
                ST_Buffer(ST_Transform(geom,3857), 100,  'endcap=round join=round')),
                4326);

-- write the table contents to a .csv file
COPY
(
    select
    street,
    osmid,
    ST_AsText(geom) AS geom,
    ST_AsText(buffer_20_metres) AS buffer_20_metres,
    ST_AsText(buffer_100_metres) AS buffer_100_metres,
    ST_AsText(buffer_200_metres) AS buffer_200_metres
from streetSample
    )
TO '/path/to/file/streetSample_with_buffers.csv' DELIMITER ',' CSV HEADER;