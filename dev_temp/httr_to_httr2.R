function(keywords = "四川省",
         key = '3d589310853c97b1d1e48a1522b8328d',
         subdistrict = NULL,
         page = NULL,
         offset = NULL,
         extensions = NULL,
         filter = NULL,
         callback = NULL,
         output = "data.table",
         keep_bad_request = TRUE,

         if (is.null(key)) {
           if (is.null(getOption("amap_key"))) {
             stop(
               "Please set key argument or set amap_key globally by this command
               options(amap_key = your key)",
               call. = FALSE
             )
           }
           key <- getOption("amap_key")
         }

         base_url <- "https://restapi.amap.com/v3/config/district"

         query_parm <- list(
           key = key,
           keywords = keywords,
           subdistrict = subdistrict,
           page = page,
           offset = offset,
           extensions = extensions,
           filter = filter,
           callback = callback,
           output = output
         )


         # GET a response with full url --------------------------------------------
         req <- httr2::request(base_url) |>
           httr2::req_url_query(key = key,
                                keywords = keywords,
                                subdistrict = subdistrict,
                                page = page,
                                offset = offset,
                                extensions = extensions,
                                filter = filter,
                                callback = callback,
                                output = output)

         key = "123"

         httr2::req_error(req) |>
           httr2::req_perform()

         # res <-
         #   httr::RETRY("GET", url = base_url, query = query_parm)

         if (!keep_bad_request) {
           res <- httr2::req_perform(req)
         } else {
           res <- httr2::req_error(req,
                                 paste0(keywords,
                                        "makes an unsuccessfully request"))
         }

         res_content <-
           httr::content(res)

         # Transform response to data.table or return directly ---------

         if (is.null(output)) {
           return(extractAdmin(res_content))
         } else {
           return(res_content)
         }
         }
