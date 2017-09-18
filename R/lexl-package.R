#' @useDynLib lexl
#' @importFrom Rcpp sourceCpp
NULL

#' lexl: Parse Excel formulas into tokens.
#'
#' `lex_xl` takes an Excel formula and separates it into tokens.  It returns a
#' dataframe, one row per token, giving the token itself, its type (e.g.
#' `number`, or `error`), and its level.
#'
#' The parse tree is designed for analysis rather than computation, and may not
#' support computation.
#'
#' A simple `plot()` function is provided that depends on the suggested
#' package `ggraph` (which pulls in many other dependencies that can be tricky
#' to install).
#'
#' @section Functions:
#' * [lexl::lex_xl()] Tokenise (lex) an Excel formula.
#' * [lexl::is_range()] Test whether an Excel formula refers to a range of cells
#' * [`plot()`][lexl::lexl_igraph()] Draw a simple tree plot of a parse tree from [lexl::lex_xl()]
#' * [lexl::lexl_edges()] Utility function used by [`plot()`][lexl::lexl_igraph()]
#' * [lexl::lexl_vertices()] Utility function used by [`plot()`][lexl::lexl_igraph()]
#' * [lexl::lexl_igraph()] Utility function used by [`plot()`][lexl::lexl_igraph()]
#' * [lexl::demo_lexl()] Shiny app to tokenise formulas and view their parse
#' tree
#'
#' @docType package
#' @name lexl
NULL
