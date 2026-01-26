#' Geocoding Module UI
#'
#' @param id Module ID
#' @export
mod_geocode_ui <- function(id) {
  ns <- shiny::NS(id)
  
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::radioButtons(ns("mode"), "Input Mode:", choices = c("Single Address", "Batch File (CSV)")),
      
      # Single Input
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'Single Address'", ns("mode")),
        shiny::textInput(ns("address"), "Address", placeholder = "e.g., Sichuan Museum"),
        shiny::textInput(ns("city"), "City (Optional)", placeholder = "e.g., Chengdu"),
        shiny::actionButton(ns("btn_single"), "Get Coordinate", class = "btn-success")
      ),
      
      # Batch Input
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'Batch File (CSV)'", ns("mode")),
        shiny::fileInput(ns("file"), "Upload CSV", accept = ".csv"),
        shiny::uiOutput(ns("col_select")),
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

#' Geocoding Module Server
#'
#' @param id Module ID
#' @return Reactive expression containing the geocoded data
#' @export
mod_geocode_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive Data container
    geo_data <- shiny::reactiveVal(NULL)
    
    # Single Geocode
    shiny::observeEvent(input$btn_single, {
      shiny::req(input$address)
      tryCatch({
        shiny::withProgress(message = 'Geocoding...', {
          city_val <- if(nzchar(input$city)) input$city else NULL
          # Call amapGeocode function
          res <- amapGeocode::getCoord(input$address, city = city_val)
          geo_data(res)
        })
      }, error = function(e) {
        shiny::showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Batch Geocode - File Reading
    file_data <- shiny::reactive({
      shiny::req(input$file)
      readr::read_csv(input$file$datapath, show_col_types = FALSE)
    })
    
    output$col_select <- shiny::renderUI({
      shiny::req(file_data())
      shiny::selectInput(ns("col"), "Select Address Column", choices = names(file_data()))
    })
    
    # Batch Processing with Async
    shiny::observeEvent(input$btn_batch, {
      shiny::req(file_data(), input$col)
      df <- file_data()
      addresses <- df[[input$col]]
      
      # Use promises/future for async
      if (requireNamespace("future", quietly = TRUE) && requireNamespace("promises", quietly = TRUE)) {
        future::plan(future::multisession)
        
        shiny::withProgress(message = 'Batch Geocoding (Async)...', value = 0, {
          
          # Future promise
          promises::future_promise({
            # Inside the future, we can't access reactive inputs directly, but we passed 'addresses'
            amapGeocode::getCoord(as.character(addresses), batch = TRUE)
          }) |>
            promises::then(function(res) {
              final <- dplyr::bind_cols(df, res)
              geo_data(final)
              shiny::showNotification("Batch processing complete!", type = "message")
            }) |>
            promises::catch(function(e) {
              shiny::showNotification(paste("Async Error:", e$message), type = "error")
            })
          
          # Since we can't easily update progress bar from future without IPC (keeping it simple for MVP),
          # we just show an indeterminate progress or "Processing in background".
          # For better UX, we'd use 'ipc' package, but let's stick to core async first.
        })
        
      } else {
        # Fallback to sync
        shiny::withProgress(message = 'Batch Geocoding...', value = 0, {
          res <- amapGeocode::getCoord(as.character(addresses), batch = TRUE)
          final <- dplyr::bind_cols(df, res)
          geo_data(final)
        })
      }
    })
    
    # Table Rendering
    output$tbl <- DT::renderDT({
      shiny::req(geo_data())
      DT::datatable(geo_data(), options = list(scrollX = TRUE))
    })
    
    # Download Handler
    output$dl_btn <- shiny::renderUI({
      shiny::req(geo_data())
      shiny::downloadButton(ns("dl_csv"), "Download CSV")
    })
    
    output$dl_csv <- shiny::downloadHandler(
      filename = function() { paste("geocoded_", Sys.Date(), ".csv", sep = "") },
      content = function(file) {
        readr::write_csv(geo_data(), file)
      }
    )
    
    # Return reactive data for other modules (e.g., map)
    return(geo_data)
  })
}
