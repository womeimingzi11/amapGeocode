library(shiny)
library(bslib)
library(DT)
library(readr)
library(leaflet)
library(amapGeocode)

# Load Modules (in a package context, these would be loaded via namespace)
# For development/local running, we source them if needed, but assuming package install:
# amapGeocode:::mod_geocode_ui
# However, since they are in R/, they are loaded with the package.

# Define UI
ui <- page_sidebar(
  title = "amapGeocode Explorer",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  sidebar = sidebar(
    width = 300,
    title = "Navigation",
    navset_pill_list(
      id = "nav",
      well = FALSE,
      nav_panel("Geocoding", icon = icon("map-marker-alt"), value = "geocode"),
      nav_panel("Reverse Geocoding", icon = icon("globe-asia"), value = "reverse"),
      nav_panel("Admin Regions", icon = icon("map"), value = "admin"),
      nav_panel("Convert Coords", icon = icon("exchange-alt"), value = "convert"),
      nav_panel("Map View", icon = icon("map-marked-alt"), value = "map"),
      nav_panel("Settings", icon = icon("cogs"), value = "settings")
    ),
    hr(),
    div(
      class = "text-muted small",
      "Powered by amapGeocode"
    )
  ),
  
  tags$head(tags$style(HTML("
    /* Custom style to make navset_pill_list take full width in sidebar */
    .sidebar-content .row > [class*='col-']:first-child { 
      width: 100%; 
      flex: 0 0 100%; 
      max-width: 100%; 
    }
    .sidebar-content .row > [class*='col-']:last-child { 
      display: none; 
    }
    /* Improve nav link wrapping */
    .nav-pills .nav-link { 
      white-space: normal; 
      line-height: 1.2; 
      padding-top: 10px;
      padding-bottom: 10px;
    }
  "))),

  # Settings Panel
  conditionalPanel(
    condition = "input.nav == 'settings'",
    mod_settings_ui("settings")
  ),
  
  # Geocoding Panel
  conditionalPanel(
    condition = "input.nav == 'geocode'",
    card(
      card_header("Geocoding (Address -> Coordinates)"),
      mod_geocode_ui("geocode")
    )
  ),
  
  # Reverse Geocoding Panel
  conditionalPanel(
    condition = "input.nav == 'reverse'",
    card(
      card_header("Reverse Geocoding (Coordinates -> Location)"),
      mod_regeo_ui("regeo")
    )
  ),
  
  # Admin Region Panel
  conditionalPanel(
    condition = "input.nav == 'admin'",
    card(
      card_header("Administrative Region Search"),
      mod_admin_ui("admin")
    )
  ),
  
  # Convert Panel
  conditionalPanel(
    condition = "input.nav == 'convert'",
    card(
      card_header("Coordinate Conversion"),
      mod_convert_ui("convert")
    )
  ),
  
  # Map Panel
  conditionalPanel(
    condition = "input.nav == 'map'",
    mod_map_ui("map")
  )
)

# Define Server
server <- function(input, output, session) {
  
  mod_settings_server("settings")
  
  # We capture the returned reactive data if we want to use it later (e.g. mapping)
  geo_results <- mod_geocode_server("geocode")
  regeo_results <- mod_regeo_server("regeo")
  admin_results <- mod_admin_server("admin")
  convert_results <- mod_convert_server("convert")
  
  # Unified data stream for Map
  # We update 'map_data' whenever one of the results changes.
  # The latest non-null result takes precedence.
  map_data <- reactiveVal(NULL)
  
  observeEvent(geo_results(), {
    req(geo_results())
    map_data(geo_results())
  })
  
  observeEvent(regeo_results(), {
    req(regeo_results())
    map_data(regeo_results())
  })
  
  observeEvent(admin_results(), {
    req(admin_results())
    map_data(admin_results())
  })
  
  mod_map_server("map", map_data)
}

shinyApp(ui, server)
