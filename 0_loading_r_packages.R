# loading the r packages required


### 
library(conflicted)
#
library(tidyverse)
conflicts_prefer(dplyr::filter)

library(dplyr)
conflict_prefer(name = "filter",    winner = "dplyr", losers = "stats")
conflict_prefer(name = "lag",       winner = "dplyr", losers = "stats")
conflict_prefer(name = "intersect", winner = "dplyr", losers = "base")
conflict_prefer(name = "setdiff",   winner = "dplyr", losers = "base")
conflict_prefer(name = "setequal",  winner = "dplyr", losers = "base")
conflict_prefer(name = "union",     winner = "dplyr", losers = "base")

library(tibble)
###
## install openeddy
#install.packages("devtools")
# devtools::install_github("lsigut/openeddy")
library(openeddy)

if (packageVersion("openeddy") < package_version("0.0.0.9009"))
  warning("this version of workflow works reliably only with openeddy version ",
          "'0.0.0.9009'")

conflict_prefer("units", "openeddy")

####

library(openair)
library(lubridate)

library(REddyProc)
packageVersion("REddyProc") # should be more than 1.3.0
library(here)

#library(FREddyPro)

library(janitor)
#
library(rmarkdown)
library(ggmap)
library(leaflet)
library(sf)
library(padr)
#library(osmdata)

library(ggpmisc)


# need to install Rtools


# install.packages("remotes")
#remotes::install_github("lsigut/openeddy")



#


library(gridExtra)

library(reshape2)

library(bigleaf)

library(mlegp)




