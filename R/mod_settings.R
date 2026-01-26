#' Settings Module UI
#'
#' @param id Module ID
#' @export
mod_settings_ui <- function(id) {
  ns <- shiny::NS(id)
  
  bslib::card(
    bslib::card_header("API Configuration"),
    bslib::card_body(
      shiny::passwordInput(ns("api_key"), "AutoNavi API Key", value = getOption("amap_key", "")),
      shiny::helpText("Enter your AutoNavi API Key. If you set 'amap_key' in options, it's pre-filled."),
      shiny::actionButton(ns("save_key"), "Save Key", class = "btn-primary"),
      shiny::hr(),
      shiny::h5("Rate Limiting"),
      shiny::numericInput(ns("max_active"), "Max Concurrent Requests", value = 3, min = 1, max = 20),
      shiny::numericInput(ns("throttle_rate"), "Throttle Rate (req/s)", value = 3, min = 1, max = 50),
      shiny::actionButton(ns("save_config"), "Update Config", class = "btn-info")
    )
  )
}

#' Settings Module Server
#'
#' @param id Module ID
#' @export
mod_settings_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    
    shiny::observeEvent(input$save_key, {
      options(amap_key = input$api_key)
      shiny::showNotification("API Key saved to options!", type = "message")
    })
    
    shiny::observeEvent(input$save_config, {
      amapGeocode::amap_config(max_active = input$max_active, throttle = list(rate = input$throttle_rate))
      shiny::showNotification("Configuration updated!", type = "message")
    })
  })
}
