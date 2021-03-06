library(lfe)
library(tidyverse)
library(ggthemes)


setwd("/run/media/john/1TB/SpiderOak/Projects/adaptation-along-the-envelope/")
cropdat <- readRDS("data/full_ag_data.rds")
cropdat <- filter(cropdat, year < 2010)
cropdat$dday0_10 <- cropdat$dday0C - cropdat$dday10C
cropdat$dday10_30 <- cropdat$dday10C - cropdat$dday30C

dummyCreator <- function(invec, prefix = NULL) {
     L <- length(invec)
     ColNames <- sort(unique(invec))
     M <- matrix(0L, ncol = length(ColNames), nrow = L,
                 dimnames = list(NULL, ColNames))
     M[cbind(seq_len(L), match(invec, ColNames))] <- 1L
     if (!is.null(prefix)) colnames(M) <- paste(prefix, colnames(M), sep = "_")
     M
} 

#cropdat <- filter(cropdat, state == "wi")
#cropdat
# # Constant prices
cropdat$corn_rprice <- mean(cropdat$corn_rprice, na.rm = TRUE)
cropdat$cotton_rprice <- mean(cropdat$cotton_rprice, na.rm = TRUE)
cropdat$hay_rprice <- mean(cropdat$hay_rprice, na.rm = TRUE)
cropdat$wheat_rprice <- mean(cropdat$wheat_rprice, na.rm = TRUE)
cropdat$soybean_rprice <- mean(cropdat$soybean_rprice, na.rm = TRUE)

cropdat <- cropdat %>% 
   group_by(fips) %>% 
   mutate(avg_corn_a = mean(corn_grain_a, na.rm = TRUE),
          avg_cotton_a = mean(cotton_a, na.rm = TRUE),
          avg_hay_a = mean(hay_a, na.rm = TRUE),
          avg_soybean_a = mean(soybean_a, na.rm = TRUE),
          avg_wheat_a = mean(wheat_a, na.rm = TRUE))
 
# Total Activity
cropdat$corn <- cropdat$corn_yield*cropdat$corn_rprice
cropdat$cotton <- cropdat$cotton_yield*cropdat$cotton_rprice
cropdat$hay <- cropdat$hay_yield*cropdat$hay_rprice
cropdat$wheat <- cropdat$wheat_yield*cropdat$wheat_rprice
cropdat$soybean <- cropdat$soybean_yield*cropdat$soybean_rprice



cropdat$rev <- rowSums(cropdat[, c("corn", "cotton", "hay", "soybean", "wheat")], na.rm = TRUE)
cropdat$acres <- rowSums(cropdat[, c("corn_grain_a", "cotton_a", "hay_a", "soybean_a", "wheat_a")], na.rm = TRUE)
head(cropdat$acres)

cropdat$ln_rev <- log(1 + cropdat$rev)
cropdat$ln_acres <- log(1 + cropdat$acres)
cropdat$prec_sq <- cropdat$prec^2


# Proportion of crop acres as total of harvested_farmland_a

cropdat$corn_grain_a <- ifelse(is.na(cropdat$corn_grain_a), 0, cropdat$corn_grain_a)
cropdat$cotton_a <- ifelse(is.na(cropdat$cotton_a), 0, cropdat$cotton_a)
cropdat$hay_a <- ifelse(is.na(cropdat$hay_a), 0, cropdat$hay_a)
cropdat$wheat_a <- ifelse(is.na(cropdat$wheat_a), 0, cropdat$wheat_a)
cropdat$soybean_a <- ifelse(is.na(cropdat$soybean_a), 0, cropdat$soybean_a)


cropdat$p_corn_a <- cropdat$corn_grain_a/cropdat$acres
cropdat$p_cotton_a <- cropdat$cotton_a/cropdat$acres
cropdat$p_hay_a <- cropdat$hay_a/cropdat$acres
cropdat$p_soybean_a <- cropdat$soybean_a/cropdat$acres
cropdat$p_wheat_a <- cropdat$wheat_a/cropdat$acres

# cropdat$p_corn_a <- cropdat$corn_grain_a/cropdat$cropland_a
# cropdat$p_cotton_a <- cropdat$cotton_a/cropdat$cropland_a
# cropdat$p_hay_a <- cropdat$hay_a/cropdat$cropland_a
# cropdat$p_soybean_a <- cropdat$soybean_a/cropdat$cropland_a
# cropdat$p_wheat_a <- cropdat$wheat_a/cropdat$cropland_a

cropdat$p_corn_a <- ifelse(is.infinite(cropdat$p_corn_a), NA, cropdat$p_corn_a)
cropdat$p_cotton_a <- ifelse(is.infinite(cropdat$p_cotton_a), NA, cropdat$p_cotton_a)
cropdat$p_hay_a <- ifelse(is.infinite(cropdat$p_hay_a), NA, cropdat$p_hay_a)
cropdat$p_soybean_a <- ifelse(is.infinite(cropdat$p_soybean_a), NA, cropdat$p_soybean_a)
cropdat$p_wheat_a <- ifelse(is.infinite(cropdat$p_wheat_a), NA, cropdat$p_wheat_a)


# Find warmest counties
dat1950 <- filter(cropdat, year >= 1950 & year <= 1979)
dat1950 <- dat1950 %>% 
  group_by(state, fips) %>% 
  summarise(dday30C_1950 = mean(dday30C, na.rm = TRUE))

dat2000 <- filter(cropdat, year >= 1980 & year <= 2009)
dat2000 <- dat2000 %>% 
  group_by(state, fips) %>% 
  summarise(dday30C_2000 = mean(dday30C, na.rm = TRUE))

dat <- left_join(dat1950, dat2000, by = c("state", "fips"))
dat$tdiff <- dat$dday30C_2000 - dat$dday30C_1950

diff <- arrange(dat, -tdiff)
head(diff)

# Split into thirds by state
diff <- diff %>% 
   group_by(state) %>% 
   mutate(thirds = dplyr::ntile(tdiff, 3))

spdiff <- filter(diff, thirds == 3) # Warmest
wfips <- spdiff$fips

tpdiff <- filter(diff, thirds == 2) # Coolest
cfips <- tpdiff$fips

moddat1 <- filter(cropdat, fips %in% wfips)
moddat1$type <- "Counties that warmed the most"
moddat2 <- filter(cropdat, fips %in% cfips)
moddat2$type <- "Counties that cooled the most"

moddat1$omega <- 1
moddat2$omega <- 0

moddat <- rbind(moddat1, moddat2)
head(moddat)

moddat$tau <- ifelse(moddat$year >= 1980, 1, 0)

moddat$did <- moddat$tau*moddat$omega
moddat$trend <- moddat$year - 1949


# Use average acres in warmest counties
# moddat$corn <- ifelse(moddat$omega == 1, (moddat$corn_grain_p/moddat$avg_corn_a)*moddat$corn_rprice, moddat$corn)
# moddat$cotton <- ifelse(moddat$omega == 1, (moddat$cotton_p/moddat$avg_cotton_a)*moddat$cotton_rprice, moddat$cotton)
# moddat$hay <- ifelse(moddat$omega == 1, (moddat$hay_p/moddat$avg_hay_a)*moddat$hay_rprice, moddat$hay)
# moddat$soybean <- ifelse(moddat$omega == 1, (moddat$soybean_p/moddat$avg_soybean_a)*moddat$soybean_rprice, moddat$soybean)
# moddat$wheat <- ifelse(moddat$omega == 1, (moddat$wheat_p/moddat$avg_wheat_a)*moddat$wheat_rprice, moddat$wheat)


state_trend <- dummyCreator(moddat$state, prefix = "state")
state_trend <- state_trend*moddat$trend

# Hand computer data
a = sapply(subset(moddat, tau == 0 & omega == 0, select = rev), mean)
b = sapply(subset(moddat, tau == 0 & omega == 1, select = rev), mean)
c = sapply(subset(moddat, tau == 1 & omega == 0, select = rev), mean)
d = sapply(subset(moddat, tau == 1 & omega == 1, select = rev), mean)

# average difference
(d - c) - (b - a)
# -10.88443

# percentage difference
((d - c) / c)* 100 - ((b - a) / a)*100
#-3.037302

moddat$type <- factor(moddat$type, levels = c("Counties that warmed the most", "Counties that cooled the most"),
                      labels = c("Counties that warmed the most", "Counties that cooled the most"))

moddat$pre <- ifelse(moddat$year >= 1980, moddat$rev, NA)

ggplot(moddat, aes(year, rev, color = factor(type))) + 
  geom_smooth(method='lm',formula=y~x) + 
  theme_tufte(base_size = 12) +
  geom_hline(yintercept = 0, color = "grey") +
  annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "grey") +
  annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "grey") +
  xlab(NULL) + ylab("Crop Revenue per Acre") +
  theme(legend.position = c(0,1), 
        legend.justification = c("left", "top"), 
        legend.box.background = element_rect(colour = "grey"), 
        legend.key = element_blank(),
        legend.title = element_blank()) 
  


mod0 <- felm(ln_rev ~ tau + omega + tau + did, data = moddat)
summary(mod0)

mod1 <- felm(ln_rev ~ state_trend + tau + omega + tau + did | fips | 0 | 0, data = moddat)
summary(mod1)

mod2 <- felm(ln_rev ~ state_trend + omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod2)

mod3 <- felm(ln_rev ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | 0 | 0 | 0, data = moddat)
summary(mod3)

mod4 <- felm(ln_rev ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | 0, data = moddat)
summary(mod4)

mod5 <- felm(ln_rev ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | state | 0 | state, data = moddat)

summary(mod5)
summary(mod5, robust = TRUE) 
cl(moddat, mod5, moddat$fips)
summary(mod5)

saveRDS(mod0, "models/dd_mod0.rds")
saveRDS(mod1, "models/dd_mod1.rds")
saveRDS(mod2, "models/dd_mod2.rds")
saveRDS(mod3, "models/dd_mod3.rds")
saveRDS(mod4, "models/dd_mod4.rds")
saveRDS(mod5, "models/dd_mod5.rds")
 

##################

# Acres

moda <- felm(ln_acres ~ tau + omega + tau + did, data = moddat)
summary(mod0)

modb <- felm(ln_acres ~ state_trend + tau + omega + tau + did | fips | 0 | 0, data = moddat)
summary(mod1)

modc <- felm(ln_acres ~ state_trend + omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod2)

modd <- felm(ln_acres ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | 0 | 0 | 0, data = moddat)
summary(mod3)

mode <- felm(ln_acres ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | 0, data = moddat)
summary(mod4)

modf <- felm(ln_acres ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod5) 

saveRDS(moda, "models/dd_moda.rds")
saveRDS(modb, "models/dd_modb.rds")
saveRDS(modc, "models/dd_modc.rds")
saveRDS(modd, "models/dd_modd.rds")
saveRDS(mode, "models/dd_mode.rds")
saveRDS(modf, "models/dd_modf.rds")

# Individual crop changes

mod1a <- felm(log(corn) ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod1a) 

mod2a <- felm(log(cotton) ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod2a) 

mod3a <- felm(log(hay) ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod3a) 


mod4a <- felm(log(soybean) ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod4a) 

mod5a <- felm(log(wheat) ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod5a) 

saveRDS(mod1a, "models/dd_mod1a.rds")
saveRDS(mod2a, "models/dd_mod2a.rds")
saveRDS(mod3a, "models/dd_mod3a.rds")
saveRDS(mod4a, "models/dd_mod4a.rds")
saveRDS(mod5a, "models/dd_mod5a.rds")

# Crop Shares

# Convert to z-scores
zcorn <- scale(moddat$p_corn_a, center = TRUE, scale = TRUE)
zcotton <- scale(moddat$p_cotton_a, center = TRUE, scale = TRUE)
zhay <- scale(moddat$p_hay_a, center = TRUE, scale = TRUE)
zsoybean <- scale(moddat$p_soybean_a, center = TRUE, scale = TRUE)
zwheat <- scale(moddat$p_wheat_a, center = TRUE, scale = TRUE)


mod1b <- felm(p_corn_a ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod1b) 

mod2b <- felm(p_cotton_a ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod2b) 

mod3b <- felm(p_hay_a ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod3b) 


mod4b <- felm(p_soybean_a ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod4b) 

mod5b <- felm(p_wheat_a ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did  | fips | 0 | state, data = moddat)
summary(mod5b) 

saveRDS(mod1b, "models/dd_mod1b.rds")
saveRDS(mod2b, "models/dd_mod2b.rds")
saveRDS(mod3b, "models/dd_mod3b.rds")
saveRDS(mod4b, "models/dd_mod4b.rds")
saveRDS(mod5b, "models/dd_mod5b.rds")



mod1b <- zcorn ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did

mod2b <- zcotton ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did

mod3b <- zhay ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did

mod4b <- zsoybean ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did

mod5b <- zwheat ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did

mod <- systemfit(list(mod1b, mod2b, mod3b,mod4b, mod5b), data = moddat, method = "SUR", 
                 useMatrix = TRUE, solvetol = 1e-40)
summary(mod)
mod$eq



# Trend

moddat$tau <- moddat$trend
moddat$did <- moddat$trend*moddat$omega

moda <- felm(ln_acres ~ tau + omega + did + omega:trend, data = moddat)
summary(mod0)

modb <- felm(ln_acres ~ state_trend + tau + omega + did | fips | 0 | 0, data = moddat)
summary(mod1)

modc <- felm(ln_acres ~ state_trend + tau + omega + did  | fips | 0 | state, data = moddat)
summary(mod2)

modd <- felm(ln_acres ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               tau + omega + did  | 0 | 0 | 0, data = moddat)
summary(mod3)

mode <- felm(ln_acres ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               tau + omega + did   | fips | 0 | 0, data = moddat)
summary(mod4)

modf <- felm(ln_acres ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               tau + omega + did   | fips | 0 | state, data = moddat)
summary(mod5) 

saveRDS(moda, "models/dd_moda.rds")
saveRDS(modb, "models/dd_modb.rds")
saveRDS(modc, "models/dd_modc.rds")
saveRDS(modd, "models/dd_modd.rds")
saveRDS(mode, "models/dd_mode.rds")
saveRDS(modf, "models/dd_modf.rds")

mod0 <- felm(ln_acres ~ tau + omega + tau + did, data = moddat)
summary(mod0)

mod1 <- felm(ln_rev ~ tau + omega + tau + did + state_trend | fips, data = moddat)

#mod2 <- felm(ln_rev ~ tau + omega + tau + did | fips + year, data = moddat)

mod2 <- felm(ln_acres ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               tau + omega + tau + did | 0 | 0 | state, data = moddat)
summary(mod2)

mod3 <- felm(ln_rev ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               tau + omega + tau + did + state_trend | fips, data = moddat)

mod4 <- felm(ln_rev ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
              tau + omega + tau + did | fips + year, data = moddat)

# summary(mod1)
# summary(mod2)
# summary(mod3)
# summary(mod4)


 saveRDS(mod0, "models/dd_mod0.rds")
 saveRDS(mod1, "models/dd_mod1.rds")
 saveRDS(mod2, "models/dd_mod2.rds")
 saveRDS(mod3, "models/dd_mod3.rds")
 saveRDS(mod4, "models/dd_mod4.rds")
 saveRDS(mod5, "models/dd_mod5.rds")
 

#---------------------------
# Bootstrapping Regression

bs.dd_reg <- function (dat, model, state_trend) {
   cropdat <- dat
   cropdat$rand <- 1
   
   rfips <- sample(unique(cropdat$fips), size = length(unique(cropdat$fips))/2)
   
   cropdat$rand <- ifelse(cropdat$fips %in% rfips, 0, 1)
   
  cropdat$corn <- ifelse(cropdat$rand == 0, (cropdat$corn_grain_p/cropdat$avg_corn_a)*cropdat$corn_rprice, cropdat$corn)
  cropdat$cotton <- ifelse(cropdat$rand == 0, (cropdat$cotton_p/cropdat$avg_cotton_a)*cropdat$cotton_rprice, cropdat$cotton)
  cropdat$hay <- ifelse(cropdat$rand == 0, (cropdat$hay_p/cropdat$avg_hay_a)*cropdat$hay_rprice, cropdat$hay)
  cropdat$soybean <- ifelse(cropdat$rand == 0, (cropdat$soybean_p/cropdat$avg_soybean_a)*cropdat$soybean_rprice, cropdat$soybean)
  cropdat$wheat <- ifelse(cropdat$rand == 0, (cropdat$wheat_p/cropdat$avg_wheat_a)*cropdat$wheat_rprice, cropdat$wheat)

  cropdat$rev <- rowSums(cropdat[, c("corn", "cotton", "hay", "soybean", "wheat")], na.rm = TRUE)
  moddat <- cropdat
  
  moddat$tau <- ifelse(moddat$year >= 1980, 1, 0)
  moddat$omega <- moddat$rand
  moddat$did <- moddat$tau*moddat$omega
  #moddat$trend <- moddat$year - 1949
  #moddat$state_trend <- as.numeric(factor(moddat$state, levels = unique(moddat$state)))*moddat$trend
  # fit <- felm(ln_rev ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
  #              omega + tau + did | state | 0 | state, data = moddat, subset = sample(nrow(moddat), 
  #                                                                                    nrow(moddat)/2, 
  #                                                                                    replace = TRUE))
  if(model == 1){
  fit <- felm(ln_rev ~ omega + tau + did, data = moddat)
  return(coef(fit))
  }
  
  if(model == 2){
  fit <- felm(ln_rev ~ omega + tau + did | state | 0 | state, data = moddat)
  return(coef(fit))
  }
  
  if(model == 3){
  fit <- felm(ln_rev ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did, data = moddat)
  return(coef(fit))
  }
  
  if(model == 4){
  fit <- felm(ln_rev ~ state_trend + dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did | fips | 0 | 0, data = moddat)
  return(coef(fit))
  }
  
}
 
bs_mod1 <- lm(ln_rev ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               omega + tau + did - 1, data = moddat)
z1 <- t(replicate(1000, bs.dd_reg(moddat, 4, state_trend)))

for (i in 1:length(bs_mod1$coefficients)){
  bs_mod1$coefficients[i] <- mean(z1[, i])
  bs_mod1$se[i] <- sd(z1[, i])
}

bs_mod1
summary(bs_mod1)
 
 
 
#------------------------------------
# Without adaptation for warmest counties
setwd("/run/media/john/1TB/SpiderOak/Projects/adaptation-along-the-envelope/")
cropdat <- readRDS("data/full_ag_data.rds")
cropdat <- filter(cropdat, year < 2010)
cropdat$dday0_10 <- cropdat$dday0C - cropdat$dday10C
cropdat$dday10_30 <- cropdat$dday10C - cropdat$dday30C

cropdat <- filter(cropdat, fips %in% wfips)

#cropdat <- filter(cropdat, state == "wi")
#cropdat

# # Constant prices
cropdat$corn_rprice <- mean(cropdat$corn_rprice, na.rm = TRUE)
cropdat$cotton_rprice <- mean(cropdat$cotton_rprice, na.rm = TRUE)
cropdat$hay_rprice <- mean(cropdat$hay_rprice, na.rm = TRUE)
cropdat$wheat_rprice <- mean(cropdat$wheat_rprice, na.rm = TRUE)
cropdat$soybean_rprice <- mean(cropdat$soybean_rprice, na.rm = TRUE)

cropdat <- cropdat %>% 
   group_by(fips) %>% 
   mutate(avg_corn_a = mean(corn_grain_a, na.rm = TRUE),
          avg_cotton_a = mean(cotton_a, na.rm = TRUE),
          avg_hay_a = mean(hay_a, na.rm = TRUE),
          avg_soybean_a = mean(soybean_a, na.rm = TRUE),
          avg_wheat_a = mean(wheat_a, na.rm = TRUE))
 
# Total Activity
cropdat$corn <- cropdat$corn_yield*cropdat$corn_rprice
cropdat$cotton <- cropdat$cotton_yield*cropdat$cotton_rprice
cropdat$hay <- cropdat$hay_yield*cropdat$hay_rprice
cropdat$wheat <- cropdat$wheat_yield*cropdat$wheat_rprice
cropdat$soybean <- cropdat$soybean_yield*cropdat$soybean_rprice

set.seed(123)
cropdat$rand <- 1

rfips <- sample(unique(cropdat$fips), size = length(unique(cropdat$fips))/2)

cropdat$rand <- ifelse(cropdat$fips %in% rfips, 0, 1)

cropdat$corn <- ifelse(cropdat$rand == 0, (cropdat$corn_grain_p/cropdat$avg_corn_a)*cropdat$corn_rprice, cropdat$corn)
cropdat$cotton <- ifelse(cropdat$rand == 0, (cropdat$cotton_p/cropdat$avg_cotton_a)*cropdat$cotton_rprice, cropdat$cotton)
cropdat$hay <- ifelse(cropdat$rand == 0, (cropdat$hay_p/cropdat$avg_hay_a)*cropdat$hay_rprice, cropdat$hay)
cropdat$soybean <- ifelse(cropdat$rand == 0, (cropdat$soybean_p/cropdat$avg_soybean_a)*cropdat$soybean_rprice, cropdat$soybean)
cropdat$wheat <- ifelse(cropdat$rand == 0, (cropdat$wheat_p/cropdat$avg_wheat_a)*cropdat$wheat_rprice, cropdat$wheat)

cropdat$rev <- rowSums(cropdat[, c("corn", "cotton", "hay", "soybean", "wheat")], na.rm = TRUE)
cropdat$ln_rev <- log(1 + cropdat$rev)
cropdat$prec_sq <- cropdat$prec^2

moddat <- cropdat

moddat$tau <- ifelse(moddat$year >= 1980, 1, 0)
moddat$omega <- moddat$rand

moddat$did <- moddat$tau*moddat$omega
moddat$trend <- moddat$year - 1949
moddat$state_trend <- as.numeric(factor(moddat$state, levels = unique(moddat$state)))*moddat$trend

# Hand computer data
a = sapply(subset(moddat, tau == 0 & omega == 0, select = rev), mean)
b = sapply(subset(moddat, tau == 0 & omega == 1, select = rev), mean)
c = sapply(subset(moddat, tau == 1 & omega == 0, select = rev), mean)
d = sapply(subset(moddat, tau == 1 & omega == 1, select = rev), mean)

# average difference
(d - c) - (b - a)
# -10.88443

# percentage difference
((d - c) / c)* 100 - ((b - a) / a)*100
#-3.037302

moddat$type <- ifelse(moddat$rand == 0, "No Adaptation", "Adaptation")
moddat$type <- factor(moddat$type, levels = c("No Adaptation", "Adaptation"),
                      labels = c("No Adaptation", "Adaptation"))

moddat$pre <- ifelse(moddat$year >= 1980, moddat$rev, NA)

ggplot(moddat, aes(year, rev, color = factor(type))) + 
  geom_smooth(method='lm',formula=y~x) + 
  theme_tufte(base_size = 12) +
  geom_hline(yintercept = 0, color = "grey") +
  annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "grey") +
  annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "grey") +
  xlab(NULL) + ylab("Crop Revenue per Acre") +
  theme(legend.position = c(0,1), 
        legend.justification = c("left", "top"), 
        legend.box.background = element_rect(colour = "grey"), 
        legend.key = element_blank(),
        legend.title = element_blank()) 
  


mod0 <- felm(ln_rev ~ tau + omega + tau + did, data = moddat)

mod1 <- felm(ln_rev ~ tau + omega + tau + did + state_trend | fips, data = moddat)

#mod2 <- felm(ln_rev ~ tau + omega + tau + did | fips + year, data = moddat)

mod2 <- felm(ln_rev ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               tau + omega + tau + did, data = moddat)

mod3 <- felm(ln_rev ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
               tau + omega + tau + did + state_trend | fips, data = moddat)

mod4 <- felm(ln_rev ~ dday0_10 + dday10_30 + dday30C + prec + prec_sq + 
              tau + omega + tau + did | fips + year, data = moddat)

summary(mod0)
summary(mod1)
summary(mod2)
summary(mod3)
summary(mod4)


saveRDS(mod0, "models/dd_mod0.rds")
saveRDS(mod1, "models/dd_mod1.rds")
saveRDS(mod2, "models/dd_mod2.rds")
saveRDS(mod3, "models/dd_mod3.rds")
saveRDS(mod4, "models/dd_mod4.rds")
 
 