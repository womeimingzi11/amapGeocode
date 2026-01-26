#' Reverse Geocoding Module UI
#'
#' @param id Module ID
#' @export
mod_regeo_ui <- function(id) {
  ns <- shiny::NS(id)
  
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::radioButtons(ns("mode"), "Input Mode:", choices = c("Single Point", "Batch File (CSV)")),
      
      # Single Input
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'Single Point'", ns("mode")),
        shiny::numericInput(ns("lng"), "Longitude", value = 104.043284, step = 0.000001),
        shiny::numericInput(ns("lat"), "Latitude", value = 30.666864, step = 0.000001),
        shiny::actionButton(ns("btn_single"), "Get Location", class = "btn-success")
      ),
      
      # Batch Input
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'Batch File (CSV)'", ns("mode")),
        shiny::fileInput(ns("file"), "Upload CSV", accept = ".csv"),
        shiny::uiOutput(ns("col_select_lng")),
        shiny::uiOutput(ns("col_select_lat")),
        shiny::actionButton(ns("btn_batch"), "Batch Process", class = "btn-success")
      )
    ),
    
    # Results
    bslib::card_body(
      DT::DTOutput(ns("tbl")),
      shiny::uiOutput(ns("dl_btn"))
    )
  )
}

#' Reverse Geocoding Module Server
#'
#' @param id Module ID
#' @return Reactive expression containing the results
#' @export
mod_regeo_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    regeo_data <- shiny::reactiveVal(NULL)
    
    # Single Regeo
    shiny::observeEvent(input$btn_single, {
      shiny::req(input$lng, input$lat)
      tryCatch({
        shiny::withProgress(message = 'Reverse Geocoding...', {
          res <- amapGeocode::getLocation(input$lng, input$lat)
          regeo_data(res)
        })
      }, error = function(e) {
        shiny::showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Batch Regeo
    file_data <- shiny::reactive({
      shiny::req(input$file)
      readr::read_csv(input$file$datapath, show_col_types = FALSE)
    })
    
    output$col_select_lng <- shiny::renderUI({
      shiny::req(file_data())
      shiny::selectInput(ns("col_lng"), "Select Longitude Column", choices = names(file_data()))
    })
    
    output$col_select_lat <- shiny::renderUI({
      shiny::req(file_data())
      shiny::selectInput(ns("col_lat"), "Select Latitude Column", choices = names(file_data()))
    })
    
    shiny::observeEvent(input$btn_batch, {
      shiny::req(file_data(), input$col_lng, input$col_lat)
      df <- file_data()
      lngs <- df[[input$col_lng]]
      lats <- df[[input$col_lat]]
      
      shiny::withProgress(message = 'Batch Reverse Geocoding...', {
        res <- amapGeocode::getLocation(lngs, lats, batch = TRUE)
        final <- dplyr::bind_cols(df, res)
        regeo_data(final)
      })
    })
    
    output$tbl <- DT::renderDT({
      shiny::req(regeo_data())
      DT::datatable(regeo_data(), options = list(scrollX = TRUE))
    })
    
    output$dl_btn <- shiny::renderUI({
      shiny::req(regeo_data())
      shiny::downloadButton(ns("dl_csv"), "Download CSV")
    })
    
    output$dl_csv <- shiny::downloadHandler(
      filename = function() { paste("reverse_geocoded_", Sys.Date(), ".csv", sep = "") },
      content = function(file) {
        readr::write_csv(regeo_data(), file)
      }
    )
    
    return(regeo_data)
  })
}
