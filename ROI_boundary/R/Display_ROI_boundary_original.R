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
tower <- c(15.0787731, 49.5732575) # c(longtitude, latitude)

# Fetch boundary defined by the user as a vector of distances [m] from tower
# - test e.g.: boundary <- c(150, 300)
boundary <- 
  c(453, 489, 469, 455, 444, 410, 375, 348, 86, 82, 78, 76, 74, 73, 72, 72, 73, 
    74, 76, 78, 81, 85, 91, 97, 106, 116, 114, 113, 131, 372, 496, 500, 507, 
    519, 531, 541, 555, 562, 565, 572, 584, 605, 633, 749, 863, 1012, 1128, 
    1098, 802, 863, 871, 903, 403, 360, 328, 303, 283, 486, 466, 451, 441, 412, 
    390, 373, 360, 350, 349, 356, 367, 381, 399, 422)

# The Universal Transverse Mercator (UTM) zone of the location
UTM_zone <- 33

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
#register_google(key = "your_API_key")

# Accommodate the zoom setting to your requirements (polygon size)
map <- get_googlemap(st_coordinates(tower_sfc), zoom = 15, maptype = "satellite")

# Create the plot of polygon and tower location (cross) over Google map 
ggmap(map) + 
  geom_sf(data = polygon, col = "red", alpha = 0.3, inherit.aes = FALSE) +
  geom_sf(data = tower_sfc, pch = 3, size = 3, col = "red", inherit.aes = FALSE) 

# EOF
