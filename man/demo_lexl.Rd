% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/demo_lexl.R
\name{demo_lexl}
\alias{demo_lexl}
\title{Run a shiny app to demonstrate lexl()}
\usage{
demo_lexl()
}
\description{
Requires the \code{shiny}, \code{igraph} and \code{ggraph} packages, which you
can install with \code{install.packages(c("shiny", "igraph", "ggraph"))}.  Runs a
shiny app to demonstrate tokenizing an Excel formula with \code{lex_xl()} and
plotting the parse tree with \code{plot.lexl()}
}
\examples{
if(interactive()) {
  demo_lexl()
}
}
\seealso{
\code{\link[lexl:lex_xl]{lexl::lex_xl()}}, \code{\link[=plot.lexl]{plot.lexl()}}, \code{\link[lexl:lexl_igraph]{lexl::lexl_igraph()}}
}
