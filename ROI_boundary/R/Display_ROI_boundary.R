### Description ================================================================

# Code for visualization of fetch boundary defined by the user as a vector of
# distances [m] from a reference point (tower). The resulting polygon shows the
# interpretation of supplied fetch vector given its angular resolution. This is
# useful to compare against the region of interest from which the fetch was
# originally extracted to check for large discrepancies if angular resolution
# was too low. Please note that the boundary does not define a sharp signal
# cut-off when using it in openeddy::fetch_filter(). Fetch filter rather assures
# that only limited amount of signal comes from behind the boundary (e.g. 30% in
# case of distance with 70% signal contribution computed by a 1D footprint
# model).

# Code designed by Milan Fischer (fischer.milan@gmail.com) and rewritten for
# sf package and ggmap by Ladislav Sigut (sigut.l@czechglobe.cz). 

### Load packages and data =====================================================

library(sf)
library(ggmap)

# Example for Kresin u Pacova (CZ-Krp)
tower <- c(-96.461542, 41.144725) # c(longtitude, latitude)

# Fetch boundary defined by the user as a vector of distances [m] from tower
# - test e.g.: boundary <- c(150, 300)
boundary <- 
  c(168.780731106454,
    169.183194638855,
    170.882336040685,
    173.944967030343,
    178.495573098197,
    184.729065084478,
    192.932314955919,
    203.519207356786,
    217.087918319131,
    234.516916401058,
    220.451788128581,
    205.839787735011,
    194.429277578204,
    185.555786643288,
    178.761129490315,
    173.727376795414,
    170.236665944739,
    168.146462911406,
    167.37466236847,
    167.891480045134,
    169.71659855896,
    172.921046352203,
    177.634150686771,
    184.056869352615,
    192.484178088854,
    203.341474578383,
    214.555577013468,
    196.159384775566,
    181.952887607214,
    170.88304661899,
    162.248908651932,
    155.571616180284,
    150.51938165785,
    146.862503046101,
    144.445770895976,
    143.171547589434,
    142.98986219874,
    143.893568318863,
    145.917665980502,
    148.953103981661,
    153.293220027326,
    159.135823852179,
    166.757566095119,
    176.557016805629,
    189.366325090942,
    205.964016004746,
    227.664567120047,
    225.55200919967,
    213.119890064622,
    203.453470857287,
    196.055752325788,
    190.581875747358,
    186.795711409634,
    184.543137619479,
    183.735972035383,
    184.349522672954,
    186.440136890606,
    190.051670714264,
    195.330560062419,
    202.503101338246,
    211.900817221016,
    224.001686995719,
    239.497692905488,
    240.717576656129,
    221.939125056055,
    207.350046651755,
    195.963962894719,
    187.113752982361,
    180.339355254585,
    175.321497250216,
    171.841364205673,
    169.659295400534)

# The Universal Transverse Mercator (UTM) zone of the location
UTM_zone <- 14  #https://hub.arcgis.com/datasets/esri::world-utm-grid/

# Choose the angle that resolves the edge of each circular sector
# - the lower the plot_res, the higher the smoothness
# - plot_res takes care only of the smoothness of the curvature on the edge of a 
#   single angular sector segment. Thus it only matters if angular resolution of 
#   the boundary (orig_res) is low (e.g. if boundary = c(150, 300), orig_res = 
#   180)
# - plot_res = 1 should be sufficient for most cases
plot_res <- 1 

### Create spatial polygon based on supplied fetch boundary ====================

# Angular resolution of the original fetch distances
orig_res <- 360 / length(boundary)

# Warn user if only one point per circular sector should be produced 
if (plot_res > orig_res) 
  warning('plot_res larger than orig_res - reduce plot_res')

# Reconstruct the azimuths (assumes first one is North)
azimuths <- seq(0, 360 - orig_res, by = orig_res)

# Half of original resolution
hr <- orig_res / 2

# Compute plotting angles for each azimuth and combine them to vector
ang_l <- lapply(azimuths, 
                function(x) seq(-hr + x, hr + x, by = plot_res))
ang <- do.call(c, ang_l) 

# Specify corresponding fetch distances to each angle
distance <- rep(boundary, each = length(ang_l[[1]]))

# Convert tower location to spatial type with coordinate reference system (CRS)
tower_sfc <- st_sfc(st_point(tower), crs = "+proj=longlat +datum=WGS84") 

# Transform the projection to UTM
tower_UTM <- st_transform(tower_sfc, 
                          paste0("+proj=utm +zone=", UTM_zone, " ellps=WGS84"))
  
# Function to get XY coordinates based on distance from reference point
get_point <- function(coord, distance, angle) {
  X <- distance*cos(pi/2-angle/180*pi)+coord[1]
  Y <- distance*sin(pi/2-angle/180*pi)+coord[2]
  c(X, Y)
}

# Find location of each edge point and save it to list
# - get_point() is not vectorized
polygon_l <- vector("list", length(ang))
for (i in seq_along(ang)) {
  polygon_l[[i]] <- get_point(st_coordinates(tower_UTM), distance[i], ang[i])
}

# Create a matrix from the edge points
polygon_m <- do.call(rbind, polygon_l)

# Create polygon spatial type from edge points and assign CRS
# - to close the polygon, first coordinate must be repeated
polygon <- st_sfc(st_polygon(list(rbind(polygon_m, polygon_m[1, ]))),
                  crs = paste0("+proj=utm +zone=", UTM_zone, " ellps=WGS84"))

# Transform the projection to WGS84
polygon <- st_transform(polygon, crs = "+proj=longlat +datum=WGS84")

### Plot the polygon over Google map ===========================================

# You need to get your API key from Google (bound to credit card but free)
register_google(key = "AIzaSyDJhiYX4jWghWvuu5mfU8tKW2heufjOvyo")

# Accommodate the zoom setting to your requirements (polygon size)
map <- get_googlemap(st_coordinates(tower_sfc), zoom = 17, maptype = "satellite")

ggmap(map) + 
  geom_sf(data = polygon, col = "red", alpha = 0.3, inherit.aes = FALSE) +
  geom_sf(data = tower_sfc, pch = 3, size = 3, col = "red", inherit.aes = FALSE) 

# EOF
