library(tidyverse)

setwd("/run/media/john/1TB/SpiderOak/Projects/adaptation-along-the-envelope/")
prec <- read_csv("data/fips_precipitation_1900-2013.csv")

cs.dat <- readRDS("data/cross_section_regression_data.rds")
xsectiondat <- dplyr::select(cs.dat, state, fips, ln_corn_rrev, ln_cotton_rrev, ln_hay_rrev, 
                      ln_wheat_rrev, ln_soybean_rrev, p_corn_share, p_cotton_share, p_hay_share,
                      p_wheat_share, p_soybean_share, corn_w, cotton_w, hay_w, wheat_w, soybean_w, total_a, lat, long)
xsectiondat.dm <- dplyr::select(cs.dat, dday0_10, dday10_30, dday30C, prec)

p.dat <- readRDS("data/panel_regression_data.rds")
paneldat <- dplyr::select(p.dat, year, state, fips, ln_corn_rrev, ln_cotton_rrev, ln_hay_rrev, 
                      ln_wheat_rrev, ln_soybean_rrev, p_corn_share, p_cotton_share, p_hay_share,
                      p_wheat_share, p_soybean_share, corn_w, cotton_w, hay_w, wheat_w, soybean_w, total_a, lat, long,
                      corn_grain_a, corn_grain_p, corn_rprice)
pdat.dm <- dplyr::select(p.dat, dday0_10, dday10_30, dday30C, prec)

diff.dat <- readRDS("data/diff_regression_data.rds")
diffdat <- dplyr::select(diff.dat, year, state, fips, ln_corn_rrev, ln_cotton_rrev, ln_hay_rrev, 
                      ln_wheat_rrev, ln_soybean_rrev, p_corn_share, p_cotton_share, p_hay_share,
                      p_wheat_share, p_soybean_share, corn_w, cotton_w, hay_w, wheat_w, soybean_w, total_a, lat, long)
diffdat.dm <- dplyr::select(diff.dat, dday0_10, dday10_30, dday30C, prec)

################################
################################
# Degree day function

dd.clean <- function(x){
 dd <- x
 dd$year <- as.integer(dd$year)
 dd$fips <- as.integer(dd$fips)
 dd_dat <- left_join(dd, prec, by = c("fips", "year", "month"))
 dd_dat <- filter(dd_dat, month >= 3 & month <= 9)
 dd_dat <- filter(dd_dat, year >= 1950 & year <= 2010)

 dd_dat$X1 <- NULL
 
 dd_dat <- dd_dat %>%
   group_by(year, fips) %>%
   summarise(dday0C = sum(dday0C),
             dday8C = sum(dday8C),
             dday10C = sum(dday10C),
             dday29C = sum(dday29C),
             dday30C = sum(dday30C),
             dday32C = sum(dday32C),
             dday34C = sum(dday34C),
             prec = sum(ppt),
             tavg = mean(tavg))
 return(dd_dat)
}



################################
################################
# Cross-section function

xsection.clean <- function(x, olddata = xsectiondat.dm){
  cropdat <- x
  cropdat <- cropdat %>%
      group_by(fips) %>%
      summarise(tavg = mean(tavg, na.rm = TRUE),
                prec = mean(prec, na.rm = TRUE),
                dday0C = mean(dday0C, na.rm = TRUE),
                dday10C = mean(dday10C, na.rm = TRUE),
                dday29C = mean(dday29C, na.rm = TRUE),
                dday30C = mean(dday30C, na.rm = TRUE)) %>% 
    ungroup()
  
  
  cropdat$dday0_10 <- cropdat$dday0C - cropdat$dday10C
  cropdat$dday10_30 <- cropdat$dday10C - cropdat$dday30C
  
  cropdat$prec_sq <- cropdat$prec^2
  cropdat$tavg_sq <- cropdat$tavg^2
  
  cropdat <- ungroup(cropdat)
  cropdat <- as.data.frame(cropdat)
  cropdat <- left_join(xsectiondat, cropdat, by = "fips")
  cropdat$latlong <- cropdat$lat*cropdat$long
  #cropdat$`(Intercept)` <- 1
  
  cropdat$dday0_10 <- cropdat$dday0_10 - mean(olddata$dday0_10, na.rm = TRUE)
  cropdat$dday10_30 <- cropdat$dday10_30 - mean(olddata$dday10_30, na.rm = TRUE)
  cropdat$dday30C <- cropdat$dday30C - mean(olddata$dday30C, na.rm = TRUE)
  cropdat$prec <- cropdat$prec - mean(olddata$prec, na.rm = TRUE)
  cropdat$prec_sq <- cropdat$prec^2
  
  return(cropdat)
  }


################################
################################
# Panel function

panel.clean <- function(x, olddata = pdat.dm){
  cropdat <- x
  cropdat$prec_sq <- cropdat$prec^2
  cropdat$tavg_sq <- cropdat$tavg^2
  cropdat$dday0_10 <- cropdat$dday0C - cropdat$dday10C
  cropdat$dday10_30 <- cropdat$dday10C - cropdat$dday30C
  cropdat$lat <- NULL
  cropdat$long <- NULL
  cropdat$state <- NULL
  
  cropdat$tavg_sq <- cropdat$tavg^2
  cropdat$prec_sq <- cropdat$prec^2

  
  cropdat <- ungroup(cropdat)
  cropdat <- as.data.frame(cropdat)
  cropdat <- left_join(paneldat, cropdat, by = c("year", "fips"))
  
  cropdat$dday0_10 <- cropdat$dday0_10 - mean(olddata$dday0_10, na.rm = TRUE)
  cropdat$dday10_30 <- cropdat$dday10_30 - mean(olddata$dday10_30, na.rm = TRUE)
  cropdat$dday30C <- cropdat$dday30C - mean(olddata$dday30C, na.rm = TRUE)
  cropdat$prec <- cropdat$prec - mean(olddata$prec, na.rm = TRUE)
  cropdat$prec_sq <- cropdat$prec^2
  cropdat$`lat:long` <- cropdat$lat*cropdat$long
  cropdat$`(Intercept)` <- 1
  return(cropdat)
}


################################
################################
# Difference function

diff.clean <- function(x, olddata = diffdat.dm){
  cropdat <- x

  decade_merge <- function(dat, begd, endd, int){
    mergdat <- data.frame()
    decades <- seq(begd, endd, int)
    for (i in decades){
      int.dat <- filter(dat, year >= i & year < (i + int))
      int.dat <- int.dat %>%
     group_by(fips) %>% 
     summarise(tavg = mean(tavg, na.rm = TRUE),
              dday0C = mean(dday0C, na.rm = TRUE),
              dday10C = mean(dday10C, na.rm = TRUE),
              dday30C = mean(dday30C, na.rm = TRUE),
              prec = mean(prec, na.rm = TRUE)) %>% 
        ungroup()
      int.dat$year <- i
      mergdat <- rbind(mergdat, int.dat)
    }
    return(mergdat)
  }
  
  decadedat <- decade_merge(cropdat, 1950, 2000, 10)
  
  decadedat$dday0_10 <- decadedat$dday0C - decadedat$dday10C
  decadedat$dday10_30 <- decadedat$dday10C - decadedat$dday30C
  
  decadedat$tavg_sq <- decadedat$tavg^2
  decadedat$prec_sq <- decadedat$prec^2
  decadedat <- ungroup(decadedat)
  decadedat <- as.data.frame(decadedat)
  decadedat <- left_join(diffdat, decadedat, by = c("year", "fips"))
  
  decadedat$dday0_10 <- decadedat$dday0_10 - mean(diffdat.dm$dday0_10, na.rm = TRUE)
  decadedat$dday10_30 <- decadedat$dday10_30 - mean(diffdat.dm$dday10_30, na.rm = TRUE)
  decadedat$dday30C <- decadedat$dday30C - mean(diffdat.dm$dday30C, na.rm = TRUE)
  decadedat$prec <- decadedat$prec - mean(diffdat.dm$prec, na.rm = TRUE)
  decadedat$prec_sq <- decadedat$prec^2
  decadedat$latlong <- decadedat$lat*decadedat$long
  #decadedat$`(Intercept)` <- 1
  return(decadedat)
}


# Degree day changes 0C
dd0 <- readRDS("data/full_ag_data.rds")
dd0.xsection <- xsection.clean(dd0, xsectiondat.dm)
dd0.panel <- panel.clean(dd0)
dd0.diff <- diff.clean(dd0)

saveRDS(dd0.xsection, "data/degree_day_changes/cross_section_regression_data_0C")
saveRDS(dd0.panel, "data/degree_day_changes/panel_regression_data_0C")
saveRDS(dd0.diff, "data/degree_day_changes/diff_regression_data_0C")


# Degree day changes 1C
dd1 <- readRDS("data/degree_day_changes/fips_degree_days_1C_1900-2013.rds")
dd1 <- dd.clean(dd1)
dd1.xsection <- xsection.clean(dd1, xsectiondat.dm)
dd1.panel <- panel.clean(dd1)
dd1.diff <- diff.clean(dd1)

saveRDS(dd1.xsection, "data/degree_day_changes/cross_section_regression_data_1C")
saveRDS(dd1.panel, "data/degree_day_changes/panel_regression_data_1C")
saveRDS(dd1.diff, "data/degree_day_changes/diff_regression_data_1C")

# Degree day changes 2C
dd2 <- readRDS("data/degree_day_changes/fips_degree_days_2C_1900-2013.rds")
dd2 <- dd.clean(dd2)
dd2.xsection <- xsection.clean(dd2)
dd2.panel <- panel.clean(dd2)
dd2.diff <- diff.clean(dd2)

saveRDS(dd2.xsection, "data/degree_day_changes/cross_section_regression_data_2C")
saveRDS(dd2.panel, "data/degree_day_changes/panel_regression_data_2C")
saveRDS(dd2.diff, "data/degree_day_changes/diff_regression_data_2C")

# Degree day changes 3C
dd3 <- readRDS("data/degree_day_changes/fips_degree_days_3C_1900-2013.rds")
dd3 <- dd.clean(dd3)
dd3.xsection <- xsection.clean(dd3)
dd3.panel <- panel.clean(dd3)
dd3.diff <- diff.clean(dd3)

saveRDS(dd3.xsection, "data/degree_day_changes/cross_section_regression_data_3C")
saveRDS(dd3.panel, "data/degree_day_changes/panel_regression_data_3C")
saveRDS(dd3.diff, "data/degree_day_changes/diff_regression_data_3C")

# Degree day changes 4C
dd4 <- readRDS("data/degree_day_changes/fips_degree_days_4C_1900-2013.rds")
dd4 <- dd.clean(dd4)
dd4.xsection <- xsection.clean(dd4)
dd4.panel <- panel.clean(dd4)
dd4.diff <- diff.clean(dd4)

saveRDS(dd4.xsection, "data/degree_day_changes/cross_section_regression_data_4C")
saveRDS(dd4.panel, "data/degree_day_changes/panel_regression_data_4C")
saveRDS(dd4.diff, "data/degree_day_changes/diff_regression_data_4C")

# Degree day changes 5C
dd5 <- readRDS("data/degree_day_changes/fips_degree_days_5C_1900-2013.rds")
dd5 <- dd.clean(dd5)
dd5.xsection <- xsection.clean(dd5)
dd5.panel <- panel.clean(dd5)
dd5.diff <- diff.clean(dd5)

saveRDS(dd5.xsection, "data/degree_day_changes/cross_section_regression_data_5C")
saveRDS(dd5.panel, "data/degree_day_changes/panel_regression_data_5C")
saveRDS(dd5.diff, "data/degree_day_changes/diff_regression_data_5C")








