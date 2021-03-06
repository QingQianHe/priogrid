#! /bin/sh

# STARTUP #
date +"started %d-%m-%Y %T"



# Setup the database
createdb priogrid2
# Create the schemas
psql -d priogrid2 -c "CREATE SCHEMA orig;"
psql -d priogrid2 -c "CREATE SCHEMA dev;"
psql -d priogrid2 -c "CREATE SCHEMA test;"
# Enable PostGIS
psql -d priogrid2 -c "CREATE EXTENSION postgis;"
# Register custom functions
psql -d priogrid2 -f Scripts/_registerfuncs.sql

# PRIO-GRID
# Create the PRIO-GRID reference table
psql -d priogrid2 -f Scripts/createpriogrid.sql

# CShapes historical country borders
# Load data
shp2pgsql -d -s 4326 -I Input/cshapes/cshapes.shp orig.cshapes | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/cshapes.sql

# GWCodes lookup tables
# Load gw2iso 
psql -d priogrid2 -c "DROP TABLE IF EXISTS orig.gw2iso;"
psql -d priogrid2 -c "CREATE TABLE orig.gw2iso(cntry_name text, gwno int, isoname text, iso1num int, iso1al2 text, iso1al3 text);"
psql -d priogrid2 -c "\copy orig.gw2iso from 'Input/gw2iso.csv' CSV HEADER DELIMITER ';';"
# Load cow2gw 
psql -d priogrid2 -c "DROP TABLE IF EXISTS orig.cow2gw;"
psql -d priogrid2 -c "CREATE TABLE orig.cow2gw(gwno integer, cow integer);"
psql -d priogrid2 -c "\copy orig.cow2gw FROM 'Input/cow2gw.csv' DELIMITER ',' CSV HEADER;"








# VECTORS #



# Border distance
psql -d priogrid2 -f Scripts/borderdistance.sql

# Diamonds
# Load data
shp2pgsql -d -s 4326 -W "latin1" -I Input/diamonds/dDIAL.shp orig.diamloot | psql -d priogrid2 
shp2pgsql -d -s 4326 -W "latin1" -I Input/diamonds/dDIANL.shp orig.diamnonloot | psql -d priogrid2 
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/diamonds.sql

# Gold
# Load data
shp2pgsql -d -s 4326 -W "latin1" -I Input/gold/dGOLD_L.shp orig.goldloot | psql -d priogrid2
shp2pgsql -d -s 4326 -W "latin1" -I Input/gold/dGOLD_S.shp orig.goldsemiloot | psql -d priogrid2
shp2pgsql -d -s 4326 -W "latin1" -I Input/gold/dGOLD_NL.shp orig.goldnonloot | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/gold.sql

# Gems
# Load data
shp2pgsql -d -s 4326 -W "latin1" -I Input/gems/GEMDATA.shp orig.gems | psql -d priogrid2 
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/gems.sql

# Drugs
# Load data
shp2pgsql -d -s 4326 -W "latin1" -I Input/drugs/CANNABIS.shp orig.drugs_cannabis | psql -d priogrid2 
shp2pgsql -d -s 4326 -W "latin1" -I "Input/drugs/COCA BUSH.shp" orig.drugs_coca | psql -d priogrid2 
shp2pgsql -d -s 4326 -W "latin1" -I "Input/drugs/OPIUM POPPY.shp" orig.drugs_opium | psql -d priogrid2 
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/drugs.sql

# Petroleum
# Load data
shp2pgsql -d -s 4326 -W "latin1" -I Input/petroleum/Petrodata_Onshore_V1.2.shp orig.petron | psql -d priogrid2 
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/petroleum.sql

# GeoEPR
# Load csv file
psql -d priogrid2 -c "DROP TABLE IF EXISTS orig.epr;"
psql -d priogrid2 -c "CREATE TABLE orig.epr(gwid integer,statename text,\"from\" integer,\"to\" integer,\"group\" text,groupid integer,gwgroupid integer,umbrella integer,\"size\" numeric,status text,reg_aut text);"
psql -d priogrid2 -c "\copy orig.epr FROM 'Input/epr/EPR-2014.csv' DELIMITER ',' CSV HEADER;"
# Load shapefile
shp2pgsql -d -s 4326 -I -W "latin1" Input/geoepr/GeoEPR-2014.shp orig.geoepr | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/geoepr.sql









# RASTERS #



# Mountains
# Load data
raster2pgsql -d -I -C -Y -s 4326 Input/mountains/w001001.adf -t 500x500 orig.mountains | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/mountains.sql

# Access times
# Load data (huge data, might take time to load, 43200*21600, for perfect 1x1 degree tiles to avoid float georef alignment errors, each tile should be of size 360x120)
# (nodata value -2147483647 failed to add??)
raster2pgsql -d -I -C -Y -N -2147483647 -s 4326 Input/access/w001001.adf -t 360x120 orig.accesstimes | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/accesstimes.sql

# Gridded populations
# Load data
raster2pgsql -d -I -C -Y -s 4326 Input/population_gpw/glcount90/glp90ag/w001001.adf -t 500x500 orig.pop_gpw90 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/population_gpw/glcount95/glp95ag/w001001.adf -t 500x500 orig.pop_gpw95 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/population_gpw/glcount00/glp00ag/w001001.adf -t 500x500 orig.pop_gpw00 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/population_gpw/glfecount05/glp05ag/w001001.adf -t 500x500 orig.pop_gpw05 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/population_gpw/glfecount10/glp10ag/w001001.adf -t 500x500 orig.pop_gpw10 | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/population_gpw.sql

# IMR
# Load data
raster2pgsql -d -I -C -Y -s 4326 Input/imr/imr.asc -t 500x500 orig.imr | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/imr.sql

# Child malnutrition
# Load data
raster2pgsql -d -I -C -Y -s 4326 Input/childmalnut/uw.asc -t 500x500 orig.childmalnut | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/childmalnut.sql

# GlobCover
# Load data
raster2pgsql -d -I -C -Y -s 4326 Input/globcover/GLOBCOVER_L4_200901_200912_V2.3.tif -t 500x500 orig.globcover | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/globcover.sql

# Nordhaus
# Load data
psql -d priogrid2 -c "DROP TABLE IF EXISTS orig.nordhaus;"
psql -d priogrid2 -c "CREATE TABLE orig.nordhaus (area decimal, country text, d1 decimal, d2 decimal, d3 decimal, d4 decimal, dis_lake decimal, dis_major_river decimal, dis_ocean decimal, dis_river decimal, ELEV_SRTM decimal, ELEV_SRTM_PRED decimal, lat decimal, longitude decimal, long_name text, mattveg int, mer1990_40 decimal, mer1995_40 decimal, mer2000_40 decimal, mer2005_40 decimal, newcountryid int, popgpw_1990_40 decimal, popgpw_1995_40 decimal, popgpw_2000_40 decimal, popgpw_2005_40 decimal, ppp1990_40 decimal, ppp1995_40 decimal, ppp2000_40 decimal, ppp2005_40 decimal, prec_new decimal, precmax decimal, precmin decimal, precsd decimal, PRECAVNEW80_08 decimal, PRECSDNEW80_08 decimal, quality decimal, RIG_xi0710 decimal, rough decimal, soil_unit int, temp_new decimal, TEMPAV_8008 decimal, tempmax decimal, tempmin decimal, tempsd decimal, TEMPSD80_08 decimal, quality_revision int, \"date of last\" text);"
psql -d priogrid2 -c "\copy orig.nordhaus FROM 'Input/nordhaus/nordhaus.csv' CSV HEADER DELIMITER ';';"
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/nordhaus.sql

# Croptypes
# Load data
psql -d priogrid2 -c "DROP TABLE IF EXISTS orig.croptypes;"
psql -d priogrid2 -c "CREATE TABLE orig.croptypes(cell_ID int, row int, \"column\" int, lat numeric, lon numeric, crop int, subcrop int, area numeric, start int, \"end\" int);"
psql -d priogrid2 -c "\copy orig.croptypes from 'Input/croptypes/CELL_SPECIFIC_CROPPING_CALENDARS_30MN.TXT' CSV HEADER DELIMITER E'\t';"
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/croptypes.sql

# Precipitation GPCP (satellite)
# Load data 
# If on Linux:
raster2pgsql -d -I -C -Y -s 4326 Input/precip_gpcp/precip.mon.mean.nc -t 10x10 orig.precip_gpcp | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/precip_gpcp.sql

# Precipitation GPCC (gauge stations)
# Load data 
# If on Linux:
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/precip_gpcc/full_data_v7_05.nc":p -t 10x10 orig.precip_gpcc | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/precip_gpcc.sql

# Rain Season (based on GPCC)
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/rainseason.sql

# Temperature
# Load data 
# If on Linux:
raster2pgsql -d -I -C -Y -s 4326 Input/temp/air.mon.mean.nc -t 10x10 orig.temp | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/temp.sql

# SPI
# Prep data
# (Only file format from website we can load is ascii for each month, so this requires a Python script to download all and merge them into geotiff)
python Input/spi1/get_spi.py
python Input/spi3/get_spi.py
# Load data  (Linux and Windows)
raster2pgsql -d -I -C -Y -s 4326 Input/spi1/spi1.tif -t 10x10 orig.spi1 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/spi3/spi3.tif -t 10x10 orig.spi3 | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/spi1.sql
psql -d priogrid2 -f Scripts/spi3.sql

# Drought (SPI)
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/drought_spi.sql

# SPEIbase
# Load data
# If on Linux    (Special Ubuntu bug doesn't allow loading bottomup NetCDF, so using GeoTiff until fixed in GDAL v2.0)
gdal_translate Input/spei1_base/SPEI_01.nc Input/spei1_base/SPEI_01.tif
gdal_translate Input/spei3_base/SPEI_03.nc Input/spei3_base/SPEI_03.tif
raster2pgsql -d -I -C -Y -s 4326 Input/spei1_base/SPEI_01.tif -t 10x10 orig.spei1_base | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/spei3_base/SPEI_03.tif -t 10x10 orig.spei3_base | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/spei1_base.sql
psql -d priogrid2 -f Scripts/spei3_base.sql

# Drought (SPEIbase)
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/drought_speibase.sql

# SPEI GDM
# Load data 
# If on Linux     (Special Ubuntu bug doesn't allow loading bottomup NetCDF, so using GeoTiff until fixed in GDAL v2.0)
gdal_translate Input/spei1_gdm/spei01.nc Input/spei1_gdm/spei01.tif
gdal_translate Input/spei3_gdm/spei03.nc Input/spei3_gdm/spei03.tif
raster2pgsql -d -I -C -Y -s 4326 Input/spei1_gdm/spei01.tif -t 10x10 orig.spei1_gdm | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/spei3_gdm/spei03.tif -t 10x10 orig.spei3_gdm | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/spei1_gdm.sql
psql -d priogrid2 -f Scripts/spei3_gdm.sql

# Drought (SPEI GDM)
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/drought_speigdm.sql

# Nightlights
# Load data
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F101992.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights92 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F101993.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights93 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F121994.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights94 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F121995.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights95 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F121996.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights96 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F141997.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights97 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F141998.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights98 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F141999.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights99 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F152000.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights00 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F152001.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights01 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F152002.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights02 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F152003.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights03 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F162004.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights04 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F162005.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights05 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F162006.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights06 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F162007.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights07 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F162008.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights08 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F162009.v4b_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights09 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F182010.v4d_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights10 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F182011.v4c_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights11 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F182012.v4c_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights12 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/nightlights/F182013.v4c_web.stable_lights.avg_vis.tif -F -t 500x500 orig.nightlights13 | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/nightlights.sql

# Irrigation, historical
# Load data
raster2pgsql -d -I -C -Y -s 4326 Input/irrigation/AEI_EARTHSTAT_IR_1950.asc -t 500x500 orig.irrigation50 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/irrigation/AEI_EARTHSTAT_IR_1960.asc -t 500x500 orig.irrigation60 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/irrigation/AEI_EARTHSTAT_IR_1970.asc -t 500x500 orig.irrigation70 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/irrigation/AEI_EARTHSTAT_IR_1980.asc -t 500x500 orig.irrigation80 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/irrigation/AEI_EARTHSTAT_IR_1985.asc -t 500x500 orig.irrigation85 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/irrigation/AEI_EARTHSTAT_IR_1990.asc -t 500x500 orig.irrigation90 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/irrigation/AEI_EARTHSTAT_IR_1995.asc -t 500x500 orig.irrigation95 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/irrigation/AEI_EARTHSTAT_IR_2000.asc -t 500x500 orig.irrigation00 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/irrigation/AEI_EARTHSTAT_IR_2005.asc -t 500x500 orig.irrigation05 | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/irrigation.sql

# HYDE historical pop data...
# Load data
raster2pgsql -d -I -C -Y -s 4326 Input/population_hyde/popc_1950AD.asc -t 300x300 orig.pophyde_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/population_hyde/popc_1960AD.asc -t 300x300 orig.pophyde_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/population_hyde/popc_1970AD.asc -t 300x300 orig.pophyde_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/population_hyde/popc_1980AD.asc -t 300x300 orig.pophyde_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/population_hyde/popc_1990AD.asc -t 300x300 orig.pophyde_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/population_hyde/popc_2000AD.asc -t 300x300 orig.pophyde_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 Input/population_hyde/popc_2005AD.asc -t 300x300 orig.pophyde_2005 | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/population_hyde.sql

# ISAM-HYDE historical land use data (eg crop, pasture, forest, etc)...
# Load Data
# 1950
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":TrpEBF -t 10x10 orig.isamhyde_trpebf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":TrpDBF -t 10x10 orig.isamhyde_trpdbf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":TmpEBF -t 10x10 orig.isamhyde_tmpebf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":TmpENF -t 10x10 orig.isamhyde_tmpenf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":TmpDBF -t 10x10 orig.isamhyde_tmpdbf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":BorENF -t 10x10 orig.isamhyde_borenf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":BorDNF -t 10x10 orig.isamhyde_bordnf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":Savanna -t 10x10 orig.isamhyde_savanna_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":C3grass -t 10x10 orig.isamhyde_c3grass_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":C4grass -t 10x10 orig.isamhyde_c4grass_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":Denseshrub -t 10x10 orig.isamhyde_denseshrub_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":Openshrub -t 10x10 orig.isamhyde_openshrub_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":Tundra -t 10x10 orig.isamhyde_tundra_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":Desert -t 10x10 orig.isamhyde_desert_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":PdRI -t 10x10 orig.isamhyde_pdri_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":SecTrpEBF -t 10x10 orig.isamhyde_sectrpebf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":SecTrpDBF -t 10x10 orig.isamhyde_sectrpdbf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":SecTmpEBF -t 10x10 orig.isamhyde_sectmpebf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":SecTmpENF -t 10x10 orig.isamhyde_sectmpenf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":SecTmpDBF -t 10x10 orig.isamhyde_sectmpdbf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":SecBorENF -t 10x10 orig.isamhyde_secborenf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":SecBorDNF -t 10x10 orig.isamhyde_secbordnf_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":Water -t 10x10 orig.isamhyde_water_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":C3crop -t 10x10 orig.isamhyde_c3crop_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":C4crop -t 10x10 orig.isamhyde_c4crop_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":C3past -t 10x10 orig.isamhyde_c3past_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":C4past -t 10x10 orig.isamhyde_c4past_1950 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1950.nc":Urban -t 10x10 orig.isamhyde_urban_1950 | psql -d priogrid2
# 1960
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":TrpEBF -t 10x10 orig.isamhyde_trpebf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":TrpDBF -t 10x10 orig.isamhyde_trpdbf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":TmpEBF -t 10x10 orig.isamhyde_tmpebf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":TmpENF -t 10x10 orig.isamhyde_tmpenf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":TmpDBF -t 10x10 orig.isamhyde_tmpdbf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":BorENF -t 10x10 orig.isamhyde_borenf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":BorDNF -t 10x10 orig.isamhyde_bordnf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":Savanna -t 10x10 orig.isamhyde_savanna_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":C3grass -t 10x10 orig.isamhyde_c3grass_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":C4grass -t 10x10 orig.isamhyde_c4grass_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":Denseshrub -t 10x10 orig.isamhyde_denseshrub_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":Openshrub -t 10x10 orig.isamhyde_openshrub_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":Tundra -t 10x10 orig.isamhyde_tundra_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":Desert -t 10x10 orig.isamhyde_desert_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":PdRI -t 10x10 orig.isamhyde_pdri_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":SecTrpEBF -t 10x10 orig.isamhyde_sectrpebf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":SecTrpDBF -t 10x10 orig.isamhyde_sectrpdbf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":SecTmpEBF -t 10x10 orig.isamhyde_sectmpebf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":SecTmpENF -t 10x10 orig.isamhyde_sectmpenf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":SecTmpDBF -t 10x10 orig.isamhyde_sectmpdbf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":SecBorENF -t 10x10 orig.isamhyde_secborenf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":SecBorDNF -t 10x10 orig.isamhyde_secbordnf_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":Water -t 10x10 orig.isamhyde_water_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":C3crop -t 10x10 orig.isamhyde_c3crop_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":C4crop -t 10x10 orig.isamhyde_c4crop_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":C3past -t 10x10 orig.isamhyde_c3past_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":C4past -t 10x10 orig.isamhyde_c4past_1960 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1960.nc":Urban -t 10x10 orig.isamhyde_urban_1960 | psql -d priogrid2
# 1970
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":TrpEBF -t 10x10 orig.isamhyde_trpebf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":TrpDBF -t 10x10 orig.isamhyde_trpdbf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":TmpEBF -t 10x10 orig.isamhyde_tmpebf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":TmpENF -t 10x10 orig.isamhyde_tmpenf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":TmpDBF -t 10x10 orig.isamhyde_tmpdbf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":BorENF -t 10x10 orig.isamhyde_borenf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":BorDNF -t 10x10 orig.isamhyde_bordnf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":Savanna -t 10x10 orig.isamhyde_savanna_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":C3grass -t 10x10 orig.isamhyde_c3grass_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":C4grass -t 10x10 orig.isamhyde_c4grass_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":Denseshrub -t 10x10 orig.isamhyde_denseshrub_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":Openshrub -t 10x10 orig.isamhyde_openshrub_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":Tundra -t 10x10 orig.isamhyde_tundra_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":Desert -t 10x10 orig.isamhyde_desert_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":PdRI -t 10x10 orig.isamhyde_pdri_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":SecTrpEBF -t 10x10 orig.isamhyde_sectrpebf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":SecTrpDBF -t 10x10 orig.isamhyde_sectrpdbf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":SecTmpEBF -t 10x10 orig.isamhyde_sectmpebf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":SecTmpENF -t 10x10 orig.isamhyde_sectmpenf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":SecTmpDBF -t 10x10 orig.isamhyde_sectmpdbf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":SecBorENF -t 10x10 orig.isamhyde_secborenf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":SecBorDNF -t 10x10 orig.isamhyde_secbordnf_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":Water -t 10x10 orig.isamhyde_water_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":C3crop -t 10x10 orig.isamhyde_c3crop_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":C4crop -t 10x10 orig.isamhyde_c4crop_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":C3past -t 10x10 orig.isamhyde_c3past_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":C4past -t 10x10 orig.isamhyde_c4past_1970 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1970.nc":Urban -t 10x10 orig.isamhyde_urban_1970 | psql -d priogrid2
# 1980
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":TrpEBF -t 10x10 orig.isamhyde_trpebf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":TrpDBF -t 10x10 orig.isamhyde_trpdbf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":TmpEBF -t 10x10 orig.isamhyde_tmpebf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":TmpENF -t 10x10 orig.isamhyde_tmpenf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":TmpDBF -t 10x10 orig.isamhyde_tmpdbf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":BorENF -t 10x10 orig.isamhyde_borenf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":BorDNF -t 10x10 orig.isamhyde_bordnf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":Savanna -t 10x10 orig.isamhyde_savanna_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":C3grass -t 10x10 orig.isamhyde_c3grass_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":C4grass -t 10x10 orig.isamhyde_c4grass_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":Denseshrub -t 10x10 orig.isamhyde_denseshrub_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":Openshrub -t 10x10 orig.isamhyde_openshrub_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":Tundra -t 10x10 orig.isamhyde_tundra_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":Desert -t 10x10 orig.isamhyde_desert_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":PdRI -t 10x10 orig.isamhyde_pdri_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":SecTrpEBF -t 10x10 orig.isamhyde_sectrpebf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":SecTrpDBF -t 10x10 orig.isamhyde_sectrpdbf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":SecTmpEBF -t 10x10 orig.isamhyde_sectmpebf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":SecTmpENF -t 10x10 orig.isamhyde_sectmpenf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":SecTmpDBF -t 10x10 orig.isamhyde_sectmpdbf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":SecBorENF -t 10x10 orig.isamhyde_secborenf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":SecBorDNF -t 10x10 orig.isamhyde_secbordnf_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":Water -t 10x10 orig.isamhyde_water_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":C3crop -t 10x10 orig.isamhyde_c3crop_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":C4crop -t 10x10 orig.isamhyde_c4crop_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":C3past -t 10x10 orig.isamhyde_c3past_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":C4past -t 10x10 orig.isamhyde_c4past_1980 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1980.nc":Urban -t 10x10 orig.isamhyde_urban_1980 | psql -d priogrid2
# 1990
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":TrpEBF -t 10x10 orig.isamhyde_trpebf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":TrpDBF -t 10x10 orig.isamhyde_trpdbf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":TmpEBF -t 10x10 orig.isamhyde_tmpebf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":TmpENF -t 10x10 orig.isamhyde_tmpenf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":TmpDBF -t 10x10 orig.isamhyde_tmpdbf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":BorENF -t 10x10 orig.isamhyde_borenf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":BorDNF -t 10x10 orig.isamhyde_bordnf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":Savanna -t 10x10 orig.isamhyde_savanna_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":C3grass -t 10x10 orig.isamhyde_c3grass_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":C4grass -t 10x10 orig.isamhyde_c4grass_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":Denseshrub -t 10x10 orig.isamhyde_denseshrub_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":Openshrub -t 10x10 orig.isamhyde_openshrub_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":Tundra -t 10x10 orig.isamhyde_tundra_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":Desert -t 10x10 orig.isamhyde_desert_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":PdRI -t 10x10 orig.isamhyde_pdri_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":SecTrpEBF -t 10x10 orig.isamhyde_sectrpebf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":SecTrpDBF -t 10x10 orig.isamhyde_sectrpdbf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":SecTmpEBF -t 10x10 orig.isamhyde_sectmpebf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":SecTmpENF -t 10x10 orig.isamhyde_sectmpenf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":SecTmpDBF -t 10x10 orig.isamhyde_sectmpdbf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":SecBorENF -t 10x10 orig.isamhyde_secborenf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":SecBorDNF -t 10x10 orig.isamhyde_secbordnf_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":Water -t 10x10 orig.isamhyde_water_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":C3crop -t 10x10 orig.isamhyde_c3crop_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":C4crop -t 10x10 orig.isamhyde_c4crop_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":C3past -t 10x10 orig.isamhyde_c3past_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":C4past -t 10x10 orig.isamhyde_c4past_1990 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr1990.nc":Urban -t 10x10 orig.isamhyde_urban_1990 | psql -d priogrid2
# 2000
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":TrpEBF -t 10x10 orig.isamhyde_trpebf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":TrpDBF -t 10x10 orig.isamhyde_trpdbf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":TmpEBF -t 10x10 orig.isamhyde_tmpebf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":TmpENF -t 10x10 orig.isamhyde_tmpenf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":TmpDBF -t 10x10 orig.isamhyde_tmpdbf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":BorENF -t 10x10 orig.isamhyde_borenf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":BorDNF -t 10x10 orig.isamhyde_bordnf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":Savanna -t 10x10 orig.isamhyde_savanna_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":C3grass -t 10x10 orig.isamhyde_c3grass_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":C4grass -t 10x10 orig.isamhyde_c4grass_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":Denseshrub -t 10x10 orig.isamhyde_denseshrub_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":Openshrub -t 10x10 orig.isamhyde_openshrub_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":Tundra -t 10x10 orig.isamhyde_tundra_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":Desert -t 10x10 orig.isamhyde_desert_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":PdRI -t 10x10 orig.isamhyde_pdri_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":SecTrpEBF -t 10x10 orig.isamhyde_sectrpebf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":SecTrpDBF -t 10x10 orig.isamhyde_sectrpdbf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":SecTmpEBF -t 10x10 orig.isamhyde_sectmpebf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":SecTmpENF -t 10x10 orig.isamhyde_sectmpenf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":SecTmpDBF -t 10x10 orig.isamhyde_sectmpdbf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":SecBorENF -t 10x10 orig.isamhyde_secborenf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":SecBorDNF -t 10x10 orig.isamhyde_secbordnf_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":Water -t 10x10 orig.isamhyde_water_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":C3crop -t 10x10 orig.isamhyde_c3crop_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":C4crop -t 10x10 orig.isamhyde_c4crop_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":C3past -t 10x10 orig.isamhyde_c3past_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":C4past -t 10x10 orig.isamhyde_c4past_2000 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2000.nc":Urban -t 10x10 orig.isamhyde_urban_2000 | psql -d priogrid2
# 2010
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":TrpEBF -t 10x10 orig.isamhyde_trpebf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":TrpDBF -t 10x10 orig.isamhyde_trpdbf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":TmpEBF -t 10x10 orig.isamhyde_tmpebf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":TmpENF -t 10x10 orig.isamhyde_tmpenf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":TmpDBF -t 10x10 orig.isamhyde_tmpdbf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":BorENF -t 10x10 orig.isamhyde_borenf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":BorDNF -t 10x10 orig.isamhyde_bordnf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":Savanna -t 10x10 orig.isamhyde_savanna_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":C3grass -t 10x10 orig.isamhyde_c3grass_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":C4grass -t 10x10 orig.isamhyde_c4grass_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":Denseshrub -t 10x10 orig.isamhyde_denseshrub_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":Openshrub -t 10x10 orig.isamhyde_openshrub_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":Tundra -t 10x10 orig.isamhyde_tundra_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":Desert -t 10x10 orig.isamhyde_desert_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":PdRI -t 10x10 orig.isamhyde_pdri_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":SecTrpEBF -t 10x10 orig.isamhyde_sectrpebf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":SecTrpDBF -t 10x10 orig.isamhyde_sectrpdbf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":SecTmpEBF -t 10x10 orig.isamhyde_sectmpebf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":SecTmpENF -t 10x10 orig.isamhyde_sectmpenf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":SecTmpDBF -t 10x10 orig.isamhyde_sectmpdbf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":SecBorENF -t 10x10 orig.isamhyde_secborenf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":SecBorDNF -t 10x10 orig.isamhyde_secbordnf_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":Water -t 10x10 orig.isamhyde_water_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":C3crop -t 10x10 orig.isamhyde_c3crop_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":C4crop -t 10x10 orig.isamhyde_c4crop_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":C3past -t 10x10 orig.isamhyde_c3past_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":C4past -t 10x10 orig.isamhyde_c4past_2010 | psql -d priogrid2
raster2pgsql -d -I -C -Y -s 4326 NETCDF:"Input/isamhyde/land-cover_hyde_landcover_yr2010.nc":Urban -t 10x10 orig.isamhyde_urban_2010 | psql -d priogrid2
# Add to PRIO-GRID
psql -d priogrid2 -f Scripts/isamhyde.sql







# FINALIZE #



# Collect vars from all tables into final PRIO-GRID tables
psql -d priogrid2 -f Scripts/finalstatic.sql
psql -d priogrid2 -f Scripts/finalyearly.sql



# Finished!
date +"finished %d-%m-%Y %T"








