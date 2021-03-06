#' Searches for queries in a corpus using a specific regular expression
#'
#' Each corpus element is checked for the presence of a query. The process is repeated for multiple queries. The result is a table of queries and number of matches for each corpus row.
#'
#' @param lexicon Lexicon dataframe as parsed by the \link[lecat]{parse_lexicon} function
#' @param corpus Corpus dataframe containing search columns present in the searches dataframe
#' @param searches Data frame with the columns 'Type' and 'Column'. Queries in each Type will be located in the corresponding corpus Column
#' @param id Column name to use for identifying differing corpus samples (e.g., YouTube video id). Autogenerated if no id is provided.
#' @param regex_expression Regex expression defining search. String defining the regex expression where the string 'query' will be replaced by the actual query term
#' @param inShiny If inShiny is TRUE then shiny based notifications will be shown
#' @param case_sensitive If case_sensitive is TRUE then the search will be case sensitive
#'
#' @return run_lecat_analysis returns a data frame containing the lexicon, the corresponding search column for the query type and the frequency of terms by corpus id
run_lecat_analysis <- function(lexicon, corpus, searches, id = NaN, regex_expression = '\\Wquery\\W', inShiny = FALSE, case_sensitive = FALSE){

  # convert everything to lower case if not case sensitive
  if(!case_sensitive) {
    lexicon$Queries <- stringr::str_to_lower(lexicon$Queries)

    # turn tibble all lower case
    corpus <- corpus %>%
      dplyr::mutate_all(.funs = stringr::str_to_lower)

    # set each column in the corpus to lower case
    #for (col_name in names(corpus)) {
    #  corpus[, col_name] <-  lapply(X = corpus[, col_name], FUN = stringr::str_to_lower)
    #}
  }

  # Create custom ID
  message('Creating ID column')
  corpus$auto_id_column <- as.character(1:nrow(corpus))
  id <- 'auto_id_column'

   out <- NULL

   # output dataframe
   result <-
     data.frame(
       Type = rep(NaN, nrow(lexicon)),
       Category = rep(NaN, nrow(lexicon)),
       Query = rep(NaN, nrow(lexicon)),
       Column_examined = rep(NaN, nrow(lexicon)),
       stringsAsFactors = FALSE
     )

   counts_df <-
     as.data.frame(matrix(
       data = rep(NaN, nrow(lexicon) * nrow(corpus)),
       nrow = nrow(lexicon),
       ncol = nrow(corpus)
     ))

   result <- cbind(result, counts_df, stringsAsFactors = FALSE)

   if (inShiny) {
     n <- nrow(lexicon)
     shiny::withProgress(message = 'Searching corpus', value = 0, {
       for (i in 1:nrow(lexicon)) {
         shiny::incProgress(1/n, detail = paste("query", i))
         this_search_column <- searches$Column[lexicon$Type[i] == searches$Type]
         #out <- rbind(out,
         shiny::showNotification(paste('Query:', lexicon$Queries[i]))
          result[i,] <- run_search(corpus[,this_search_column],
                                 lexicon$Queries[i],
                                 regex_expression, lexicon$Type[i],
                                 lexicon$Category[i],
                                 corpus[,id],
                                 this_search_column)
         #)
       }
     })
   } else {
     pb <- utils::txtProgressBar(min = 1, max = nrow(lexicon), initial = 1)
     for (i in 1:nrow(lexicon)) {
       utils::setTxtProgressBar(pb, i)
       this_search_column <- searches$Column[lexicon$Type[i] == searches$Type]
       #out <- rbind(out,
       result[i,] <- run_search(strings = corpus[,this_search_column],
                                query = lexicon$Queries[i],
                                regex = regex_expression,
                                type = lexicon$Type[i],
                                category = lexicon$Category[i],
                                ids = corpus[,id],
                                column = this_search_column)
       #)
     }
     close(pb)
   }

   result
}
