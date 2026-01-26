#' Coordinate Conversion Module UI
#'
#' @param id Module ID
#' @export
mod_convert_ui <- function(id) {
  ns <- shiny::NS(id)
  
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::radioButtons(ns("mode"), "Input Mode:", choices = c("Single Point", "Batch File (CSV)")),
      shiny::selectInput(ns("sys"), "Coordinate System", choices = c("gps", "mapbar", "baidu"), selected = "gps"),
      
      # Single Input
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'Single Point'", ns("mode")),
        shiny::textInput(ns("coords"), "Coordinates (lng,lat)", placeholder = "116.481499,39.990475"),
        shiny::actionButton(ns("btn_single"), "Convert", class = "btn-success")
      ),
      
      # Batch Input
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'Batch File (CSV)'", ns("mode")),
        shiny::fileInput(ns("file"), "Upload CSV", accept = ".csv"),
        shiny::uiOutput(ns("col_select")),
        shiny::actionButton(ns("btn_batch"), "Batch Convert", class = "btn-success")
      )
    ),
    
    # Results
    bslib::card_body(
      DT::DTOutput(ns("tbl")),
      shiny::uiOutput(ns("dl_btn"))
    )
  )
}

#' Coordinate Conversion Module Server
#'
#' @param id Module ID
#' @return Reactive expression containing the results
#' @export
mod_convert_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    conv_data <- shiny::reactiveVal(NULL)
    
    # Single Convert
    shiny::observeEvent(input$btn_single, {
      shiny::req(input$coords)
      tryCatch({
        shiny::withProgress(message = 'Converting...', {
          res <- amapGeocode::convertCoord(input$coords, coordsys = input$sys)
          conv_data(res)
        })
      }, error = function(e) {
        shiny::showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Batch Convert
    file_data <- shiny::reactive({
      shiny::req(input$file)
      readr::read_csv(input$file$datapath, show_col_types = FALSE)
    })
    
    output$col_select <- shiny::renderUI({
      shiny::req(file_data())
      shiny::selectInput(ns("col"), "Select Coords Column (lng,lat)", choices = names(file_data()))
    })
    
    shiny::observeEvent(input$btn_batch, {
      shiny::req(file_data(), input$col)
      df <- file_data()
      coords_vec <- df[[input$col]]
      
      shiny::withProgress(message = 'Batch Converting...', {
        res <- amapGeocode::convertCoord(as.character(coords_vec), coordsys = input$sys)
        final <- dplyr::bind_cols(df, res)
        conv_data(final)
      })
    })
    
    output$tbl <- DT::renderDT({
      shiny::req(conv_data())
      DT::datatable(conv_data(), options = list(scrollX = TRUE))
    })
    
    output$dl_btn <- shiny::renderUI({
      shiny::req(conv_data())
      shiny::downloadButton(ns("dl_csv"), "Download CSV")
    })
    
    output$dl_csv <- shiny::downloadHandler(
      filename = function() { paste("converted_coords_", Sys.Date(), ".csv", sep = "") },
      content = function(file) {
        readr::write_csv(conv_data(), file)
      }
    )
    
    return(conv_data)
  })
}
