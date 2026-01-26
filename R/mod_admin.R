#' Admin Region Module UI
#'
#' @param id Module ID
#' @export
mod_admin_ui <- function(id) {
  ns <- shiny::NS(id)
  
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::textInput(ns("keywords"), "Keywords (comma separated)", placeholder = "e.g., Sichuan, Chengdu"),
      shiny::selectInput(ns("subdistrict"), "Subdistrict Level", 
                  choices = c("0 (None)" = 0, "1 (Next Level)" = 1, "2" = 2, "3" = 3), 
                  selected = 1),
      shiny::radioButtons(ns("extensions"), "Extensions:", choices = c("base", "all"), inline = TRUE),
      shiny::actionButton(ns("btn_search"), "Search", class = "btn-success")
    ),
    
    bslib::card_body(
      DT::DTOutput(ns("tbl")),
      shiny::uiOutput(ns("dl_btn"))
    )
  )
}

#' Admin Region Module Server
#'
#' @param id Module ID
#' @return Reactive expression containing the admin data
#' @export
mod_admin_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    admin_data <- shiny::reactiveVal(NULL)
    
    shiny::observeEvent(input$btn_search, {
      shiny::req(input$keywords)
      
      # Split keywords by comma
      kw_vec <- trimws(strsplit(input$keywords, ",")[[1]])
      kw_vec <- kw_vec[nzchar(kw_vec)]
      
      tryCatch({
        shiny::withProgress(message = 'Searching Admin Regions...', {
          res <- amapGeocode::getAdmin(kw_vec, 
                                       subdistrict = as.integer(input$subdistrict),
                                       extensions = input$extensions)
          admin_data(res)
        })
      }, error = function(e) {
        shiny::showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    output$tbl <- DT::renderDT({
      shiny::req(admin_data())
      DT::datatable(admin_data(), options = list(scrollX = TRUE))
    })
    
    output$dl_btn <- shiny::renderUI({
      shiny::req(admin_data())
      shiny::downloadButton(ns("dl_csv"), "Download CSV")
    })
    
    output$dl_csv <- shiny::downloadHandler(
      filename = function() { paste("admin_regions_", Sys.Date(), ".csv", sep = "") },
      content = function(file) {
        readr::write_csv(admin_data(), file)
      }
    )
    
    return(admin_data)
  })
}
