#' Launch the amapGeocode Graphical Interface
#'
#' @description
#' Launches a Shiny application that provides a graphical user interface for
#' accessing the functionality of `amapGeocode`. The app supports:
#' \itemize{
#'   \item Geocoding (Address to Coordinates) - Single and Batch (CSV)
#'   \item Reverse Geocoding (Coordinates to Location) - Single and Batch (CSV)
#'   \item Coordinate Conversion - Single and Batch
#'   \item Configuration of API Key and Rate Limits
#' }
#'
#' @return
#' No return value, called for side effects (launching the application).
#'
#' @details
#' The application requires the following suggested packages:
#' `shiny`, `bslib`, `DT`, and `readr`. If they are not installed, the function
#' will prompt the user to install them.
#'
#' @examples
#' \dontrun{
#' if (interactive()) {
#'   amap_gui()
#' }
#' }
#' @export
amap_gui <- function() {
  # Check for required suggested packages
  required_pkgs <- c("shiny", "bslib", "DT", "readr", "leaflet", "future", "promises")
  missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]

  if (length(missing_pkgs) > 0) {
    rlang::abort(
      paste0(
        "The following packages are required for the GUI but are not installed: ",
        paste(missing_pkgs, collapse = ", "),
        ".\nPlease install them using install.packages()."
      )
    )
  }

  app_dir <- system.file("shiny", "amap_explorer", package = "amapGeocode")
  if (app_dir == "") {
    rlang::abort("Could not find the Shiny application directory. Try re-installing `amapGeocode`.")
  }

  shiny::runApp(app_dir, display.mode = "normal")
}
