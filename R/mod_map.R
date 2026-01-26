#' Interactive Map Module UI
#'
#' @param id Module ID
#' @export
mod_map_ui <- function(id) {
  ns <- shiny::NS(id)
  
  bslib::card(
    bslib::card_header("Map Visualization"),
    leaflet::leafletOutput(ns("map"), height = "600px"),
    bslib::card_footer("Markers are automatically added from the latest Geocoding, Reverse Geocoding, or Admin Search results.")
  )
}

#' Interactive Map Module Server
#'
#' @param id Module ID
#' @param data_reactive Reactive expression returning a data frame with 'lng' and 'lat' columns.
#' @export
mod_map_server <- function(id, data_reactive) {
  shiny::moduleServer(id, function(input, output, session) {
    
    # Initialize Map
    output$map <- leaflet::renderLeaflet({
      leaflet::leaflet() |>
        leaflet::addTiles() |>
        leaflet::setView(lng = 104.06, lat = 30.67, zoom = 10) # Default to Chengdu
    })
    
    # Observe Data Changes
    shiny::observe({
      df <- data_reactive()
      shiny::req(df)
      
      # Check for required columns
      if (all(c("lng", "lat") %in% names(df))) {
        
        # Ensure numeric
        df$lng <- as.numeric(df$lng)
        df$lat <- as.numeric(df$lat)
        df <- df[!is.na(df$lng) & !is.na(df$lat), ]
        
        if (nrow(df) > 0) {
          # Create popup content
          # Try to find a meaningful label column
          label_col <- NULL
          candidates <- c("formatted_address", "address", "name", "province", "district")
          for (cand in candidates) {
            if (cand %in% names(df)) {
              label_col <- cand
              break
            }
          }
          
          popups <- if (!is.null(label_col)) df[[label_col]] else paste(df$lat, df$lng, sep=", ")
          
          leaflet::leafletProxy("map", data = df) |>
            leaflet::clearMarkers() |>
            leaflet::addMarkers(lng = ~lng, lat = ~lat, popup = popups) |>
            leaflet::fitBounds(min(df$lng), min(df$lat), max(df$lng), max(df$lat))
        }
      }
    })
  })
}
