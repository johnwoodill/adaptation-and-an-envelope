library(choroplethr)
library(ggthemes)
library(cowplot)
# Load data
# gr <- readRDS("data/full_ag_data.rds")
# mapdat <- data.frame(region = unique(gr$fips))
# mapdat$value <- 1
# 
# dd_map <- county_choropleth(mapdat,
#                  title      = NULL,
#                  num_colors = 2)
#      
#                 state_zoom = c("texas", "kansas", "illinois", "kentucky", "north carolina", "oklahoma", "south carolina", "tennessee",
#                                 "virginia", "alabama", "missouri", "georgia", "arkansas", "mississippi", "louisiana"))
# dd_map+ theme(legend.position = "none")+ scale_fill_brewer(palette = "Paired") + ggtitle("Map of Selected Counties from 1950-2010")
# 

grr <- readRDS("data/full_ag_data.rds")
gr <- filter(grr, year == 1950)
#gr <- grr
mapdat <- data.frame(region = unique(gr$fips))

grr$state <- toupper(factor(grr$state))
states <- tolower(unique(state.name[match(grr$state, state.abb)]))
states <- states[!is.na(states)]                     

crops <- gr %>% 
  group_by(fips) %>% 
  summarise(corn_a = mean(corn_grain_a, na.rm = TRUE),
            cotton_a = mean(cotton_a, na.rm = TRUE),
            hay_a = mean(hay_a, na.rm = TRUE),
            wheat_a = mean(wheat_a, na.rm = TRUE),
            soybean_a = mean(soybean_a, na.rm = TRUE))

crops$state <- NULL
mapdat <- left_join(mapdat, crops, by = c("region" = "fips"))
mapdat <- gather(mapdat, region)
names(mapdat) <- c("region", "crop", "value")
mapdat <- filter(mapdat, value > 0 & !is.na(value))
mapdat <- spread(mapdat, key = crop, value)
fipss <- unique(mapdat$region)

# Categorize counties with variables
# mapdat$corn <- ifelse(is.na(mapdat$corn_a), 0, 1)
# mapdat$cotton <- ifelse(is.na(mapdat$cotton_a), 0, 1)
# mapdat$hay <- ifelse(is.na(mapdat$hay_a), 0, 1)
# mapdat$wheat <- ifelse(is.na(mapdat$wheat_a), 0, 1)
# mapdat$soybean <- ifelse(is.na(mapdat$soybean_a), 0, 1)
# mapdat$value <- rowSums(mapdat[,c("corn", "cotton", "hay", "wheat", "soybean")], na.rm = TRUE)
# 
# mapdat <- select(mapdat, region, value)

# Map plot
#mapdat$value <- sample(1:5, 2474, replace = TRUE)
# county_choropleth(mapdat,
#                  title      = NULL,
#                  num_colors = 5)
# ,
#                  state_zoom = states)
# 
# mapp + scale_fill_brewer(palette = "Accent") + ggtitle("Map of Selected Counties from 1930-2010")
# 
# mapp  + ggtitle("Map of Selected Counties from 1930-2010")
# 
# counties <- unique(mapdat$region)

# Corn
corndat <- select(mapdat, region, corn_a) %>% filter(!is.na(corn_a)) %>%  rename(region = region, value = corn_a)
cornfips <- corndat$region
corn_map <- county_choropleth(corndat,
                 title      = NULL, state_zoom = states)
     
                
corn_map <- corn_map + scale_fill_brewer(palette = "YlGnBu") + 
  theme_tufte(base_size = 14)+ 
  xlab("Corn") + ylab(NULL) + theme(legend.position = "none",
                       axis.text.x = element_blank(),
                       axis.text.y = element_blank(),
                       axis.ticks.x = element_blank(),
                       axis.ticks.y = element_blank(),
                       panel.border = element_rect(fill = NA)) 
  
corn_map

# Cotton
cottondat <- select(mapdat, region, cotton_a) %>% filter(!is.na(cotton_a)) %>%  rename(region = region, value = cotton_a)
cottonfips <- cottondat$region
cotton_map <- county_choropleth(cottondat, state_zoom = c("texas", "oklahoma", "kansas", "missouri", "tennessee", "kentucky", "virginia",
                                                          "south carolina", "georgia", "alabama", "mississippi", "arkansas", "louisiana",
                                                          "florida", "north carolina"),
                 title      = NULL)
     
                
cotton_map <- cotton_map + scale_fill_brewer(palette = "YlGnBu") + 
  theme_tufte(base_size = 14)+
  xlab("Cotton") + ylab(NULL) + theme(legend.position = "none",
                       axis.text.x = element_blank(),
                       axis.text.y = element_blank(),
                       axis.ticks.x = element_blank(),
                       axis.ticks.y = element_blank(),
                       panel.border = element_rect(fill = NA))
cotton_map

# Hay
haydat <- select(mapdat, region, hay_a) %>% filter(!is.na(hay_a)) %>%  rename(region = region, value = hay_a)
hayfips <- haydat$region
hay_map <- county_choropleth(haydat, 
                 title      = NULL, state_zoom = states)
     
                
hay_map <- hay_map + scale_fill_brewer(palette = "YlGnBu") + 
  theme_tufte(base_size = 14)+ 
  xlab("Hay") + ylab(NULL) + theme(legend.position = "none",
                       axis.text.x = element_blank(),
                       axis.text.y = element_blank(),
                       axis.ticks.x = element_blank(),
                       axis.ticks.y = element_blank(),
                       panel.border = element_rect(fill = NA))
hay_map

# Wheat
wheatdat <- select(mapdat, region, wheat_a) %>% filter(!is.na(wheat_a)) %>%  rename(region = region, value = wheat_a)
wheatfips <- wheatdat$region
wheat_map <- county_choropleth(wheatdat, 
                 title      = NULL, state_zoom = states)
     
                
wheat_map <- wheat_map + scale_fill_brewer(palette = "YlGnBu") + 
  theme_tufte(base_size = 14)+ 
  xlab("Wheat") + ylab(NULL) + theme(legend.position = "none",
                       axis.text.x = element_blank(),
                       axis.text.y = element_blank(),
                       axis.ticks.x = element_blank(),
                       axis.ticks.y = element_blank(),
                       panel.border = element_rect(fill = NA))
wheat_map

# Soybean
soybeandat <- select(mapdat, region, soybean_a) %>% filter(!is.na(soybean_a)) %>%  rename(region = region, value = soybean_a)
soybeanfips <- soybeandat$region
soybean_map <- county_choropleth(soybeandat, 
                 title      = NULL, state_zoom = states)
     
                
soybean_map <- soybean_map + scale_fill_brewer(palette = "YlGnBu") + 
  theme_tufte(base_size = 14)+ 
  xlab("Soybean") + ylab(NULL) + theme(legend.position = "none",
                       axis.text.x = element_blank(),
                       axis.text.y = element_blank(),
                       axis.ticks.x = element_blank(),
                       axis.ticks.y = element_blank(),
                       panel.border = element_rect(fill = NA))
soybean_map

dev.off()
#pdf("/home/john/Dropbox/Research/Adaptation Along the Envelope/figures/crop_county_map.pdf", 
#    width = 6, height = 5)
plot_grid(corn_map, cotton_map, hay_map, wheat_map, soybean_map)
#dev.off()