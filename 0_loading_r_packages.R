# loading the r packages required

# need to install Rtools

library(here)

# install.packages("remotes")
#remotes::install_github("lsigut/openeddy")

library(openeddy)

if (packageVersion("openeddy") < package_version("0.0.0.9009"))
  warning("this version of workflow works reliably only with openeddy version ",
          "'0.0.0.9009'")

#
library(tibble)
library(lubridate)
library(tidyverse)
library(gridExtra)
library(reshape2)
library(REddyProc)
packageVersion("REddyProc") # should be more than 1.3.0
library(bigleaf)
library(mlegp)

library(padr)

library(openair)
