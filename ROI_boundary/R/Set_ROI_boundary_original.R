### Description ================================================================

# Code for extracting fetch distances from reference point (tower) based on
# spatial polygon defining region of interest (ROI). ROI boundary typically
# represents the outline of the target ecosystem behind which we do not wish to
# sample fluxes. This can be due to land-use type behind the boundary, presence
# of local CO2 sources, etc. Please note that the boundary does not define a
# sharp signal cut-off when using it in openeddy::fetch_filter(). Fetch filter
# rather assures that only limited amount of signal comes from behind the
# boundary (e.g. 30% in case of distance with 70% signal contribution computed
# by a 1D footprint model).
#
# Code designed by Milan Fischer (fischer.milan@gmail.com) and rewritten for
# sf package by Ladislav Sigut (sigut.l@czechglobe.cz). 
# 
# Inspired by:
# https://tinyurl.com/spatialdistance
#
# Details on S2 spherical geometry implemented in sf:
# https://r-spatial.org/r/2020/06/17/s2.html
# https://r-spatial.org/r/2017/06/22/spatial-index.html

### Load packages and data =====================================================

# Load packages
library(sf)
library(geosphere) # imports sp package, thus unclear if supported long-term
library(lwgeom) # unclear if supported long-term

# Load ROI and tower simple features
# - ROI is expected to be a polygon
# - tower is expected to be a point

# Choose one of the examples:

# Example for shapefiles
# - select the folder that contains shapefile
# ROI <- st_read('./data/folder_with_ROI')
# tower <- st_read('./data/folder_with_tower_location')

# Example for klm files (exported by Google Earth)
# - remove Z axis with st_zm()
ROI <- st_zm(st_read('./data/CZ-Krp_ROI_boundary.kml'))
tower <- st_zm(st_read('./data/CZ-Krp_tower.kml'))

### Make transects from tower location outwards in given angular resolution ====

# Obtain the coordinate reference system
# - needed for computing intersections
crs <- st_crs(ROI)

# Make plot of the geometry
plot(st_geometry(ROI), axes = TRUE)
plot(st_geometry(tower), pch = 3, add = TRUE)

# Obtain the tower coordinates
p <- st_coordinates(tower) # needed for geosphere::destPoint()

# Make a sequence of azimuths
azimuths <- seq(from = 0, to = 355, by = 5)

# Compute the transects as spatial lines (tower location - destination point)
# - not aware of substitution for destPoint if geosphere deprecated
dp <- destPoint(p = p, b = azimuths, d = 1e6) # large d assures intersection
tr_list <- apply(dp, 
                 1, 
                 function(x) st_linestring(rbind(p, x)), 
                 simplify = FALSE) # sfg class

# Convert sfg objects to sfc with CRS specification
tr <- do.call(st_sfc, list(tr_list, crs = crs))

# Create simple feature from sfc and plot transects
tr_sf <- st_sf('ID' = azimuths, 'geometry' = tr)
plot(st_geometry(tr_sf), add = TRUE)

### Compute intersections of transects with ROI boundary =======================

# Convert ROI from polygon to linestring
boundary_line <- st_cast(st_geometry(ROI),"LINESTRING")

# Should be spherical geometry used?
# - spherical S2 geometry should be better than planar
# - sf_use_s2(FALSE) st_intersection() seems to be computed on planar grid
#   and thus is likely less precise
# - sf_use_s2(FALSE) makes st_distance() to use lwgeom::st_geod_distance()
#   which should be more precise (computed on ellipsoid)
# - it appears that although computations are spherical, plotting uses 
#   Equirectangular projection (planar), thus the need for sf_use_s2(FALSE) 

# Compute planar intersections for plotting
sf_use_s2(FALSE)
inter_pl <- st_intersection(st_geometry(boundary_line), st_geometry(tr_sf))
plot(st_geometry(inter_pl), add = TRUE)

# Compute spherical intersections (more precise, not aligning with plot)
sf_use_s2(TRUE)
inter <- st_intersection(st_geometry(boundary_line), st_geometry(tr_sf))
plot(st_geometry(inter), add = TRUE)

# Distances of intersections from tower location
dist <- st_distance(st_geometry(tower), st_geometry(inter), by_element = TRUE)

# Prepare the output data frame
out <- data.frame(azimuths, dist)
colnames(out) <- c('Azimuth', 'Fetch')

# Write the output csv file
write.csv(out, './output/fetch.csv', row.names = FALSE)

# EOF
