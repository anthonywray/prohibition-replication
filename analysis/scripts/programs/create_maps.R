#########################################################################################################
#  Clear memory
rm(list = ls())

#########################################################################################################
#  Set CRAN Mirror (place where code will be downloaded from)
local({
  r <- getOption("repos")
  r["CRAN"] <- "https://mirrors.dotsrc.org/cran/"
  options(repos = r)
})

#########################################################################################################
#  Set Library paths
.libPaths('analysis/scripts/libraries/R/windows')

###################################################################################
# Load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(Cairo, ggplot2, haven, renv, sf, tidyr, tidyverse)

###################################################################################
# Settings
my_theme <- theme(
  # Background and Line themes
  axis.text = element_blank(),
  line = element_blank(), 
  rect = element_rect(fill = "white"),
  panel.background = element_rect(fill = "white"),
  panel.grid = element_blank(),
  # Text editing:
  title = element_text(face = "italic", size = 20), 
  plot.caption = element_text(size = 5),
  # Legend themes
  legend.position = "bottom",
  legend.direction = "horizontal", 
  legend.title =  element_text(size = 10),
  legend.text =  element_text(size = 10),
  legend.margin = margin(0, 0, 0, 0, "cm"),
  # Font
  #text = element_text(family = "Roboto Light")
)

# Make custom range of colors
colfunc <- colorRampPalette(c("white", c(rgb(230, 65, 115, maxColorValue = 255))))

###################################################################################

## Grab the 1930 US State shapefile from NHGIS
us_states = st_read("analysis/processed/temp/nhgis0032_shape/US_state_1930.shp") %>%
  mutate(state = floor(as.numeric(NHGISST)/10)) %>%
  filter(state != 2 & state != 15) 

# Load data for maps in main paper
map_data <- read_dta("analysis/processed/data/map_input.dta") %>%
  rename_all(tolower) %>%
  mutate(wet_cat = as.factor(wet_cat)) %>%
  inner_join(us_states, by = c("state"))

levels(map_data$wet_cat) <- c("Always Dry", "1938", "1937","1935","1934")
st_geometry(map_data) <- map_data$geometry

# Load data for map of continuous variation in wet status for appendix 
continuous_map_data <- read_dta("analysis/processed/data/map_input_continuous.dta") %>%
  rename_all(tolower) %>%
  mutate(wet_cat = as.factor(wet_cat)) %>%
  inner_join(us_states, by = c("state"))

levels(continuous_map_data$wet_cat) <- c("0% wet","1% to 49% wet","50% to 74% wet","75% to 99% wet","100% wet")
st_geometry(continuous_map_data) <- continuous_map_data$geometry

# Map of roll out of wet treatment
wet_map <- ggplot() +
  geom_sf(data = us_states) +
  geom_sf(data = map_data, aes(fill = wet_cat))+
  scale_fill_manual(values = colfunc(5)) + # WGS84
  coord_sf(crs = st_crs(4326)) + # WGS84
  my_theme + 
  # Box around legend
  labs(
    fill = "First treated year" 
  ) +
  guides(fill = guide_legend(reverse = TRUE))

ggsave(plot = wet_map, "analysis/output/main/figure_1c_wet_map.png", h = 4.5, w = 8, type = "cairo-png")

# Map of continous variation in wet treatment
continuous_map <- ggplot() +
  geom_sf(data = us_states) +
  geom_sf(data = continuous_map_data, aes(fill = wet_cat))+
  scale_fill_manual(values = colfunc(5)) + # WGS84
  coord_sf(crs = st_crs(4326)) + # WGS84
  my_theme + 
  # Box around legend
  labs(
    fill = "Share of population wet" 
  ) +
  guides(fill = guide_legend(reverse = TRUE))

ggsave(plot = continuous_map, "analysis/output/appendix/figure_c2_continuous_map.png", h = 4.5, w = 8, type = "cairo-png")
