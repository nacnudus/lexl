#' @title Plot the parse tree of a formula
#'
#' @description Requires the `igraph` and `ggraph` packages, which you
#' can install with `install.packages(c("igraph", "ggraph"))`.  Draws a
#' simple tree plot of the parse tree, showing parent-child relationships,
#' tokens and types.
#'
#' The utility functions `lexl_edges()`, `lexl_vertices()`, and `lexl_igraph()`
#' compute each stage in plotting the final graph.
#'
#' @param x parse tree from `lexl()`
#' @param ... ignored, for consistency with the base `plot()` function
#' @name lexl_igraph
#' @seealso [lexl::lex_xl()], [lexl::demo_lexl()]
#' @export
#' @examples
#' x <- lex_xl("MIN(3,MAX(2,A1))")
#'
#' lexl_edges(x)
#' lexl_vertices(x)
#'
#' if (interactive() && require(igraph, quietly = TRUE)) {
#'   lexl_igraph(x)
#' }
#'
#' if (interactive()
#'     && require(igraph, quietly = TRUE)
#'     && require(ggraph, quietly = TRUE)) {
#'   plot(x)
#' }
NULL

#' @rdname lexl_igraph
#' @export
plot.lexl <- function(x, ...) {
  if (requireNamespace("igraph", quietly = TRUE)
      && requireNamespace("ggraph", quietly = TRUE)) {
    ggraph::ggraph(lexl_igraph(x), "igraph", algorithm = "tree") +
      ggraph::geom_edge_diagonal() +
      ggraph::geom_node_label(ggplot2::aes_string(label = "label")) +
      ggplot2::theme_void()
  } else {
    stop("plot.lexl() requires the packages 'igraph' and 'ggraph'.", # nocov
         call. = FALSE)                                              # nocov
  }
}

#' @rdname lexl_igraph
#' @export
lexl_edges <- function(x) {
  x$to <- as.character(seq_len(nrow(x)))
  x$from <- c("0", x$to[-length(x$to)])
  x <- split(x, x$level)
  names(x) <- NULL
  x <- lapply(x,
                  function(x) {
                    x$from <- x$from[1]
                    x
                  })
  x <- do.call(rbind, x)
  # tibbles are not compatible with igraph
  data.frame(from = x$from,
             to = x$to,
             stringsAsFactors = FALSE)
}

#' @rdname lexl_igraph
#' @export
lexl_vertices <- function(x) {
  x$id <- as.character(seq_len(nrow(x)))
  x$label <- paste(x$token, x$type, sep = "\n")
  x <- x[c("id", "label", "type", "token")]
  # tibbles are not compatible with igraph
  rbind(data.frame(id = "0",
                   label = "root",
                   type = "root",
                   token = "root",
                   stringsAsFactors = FALSE), x)
}

#' @rdname lexl_igraph
#' @export
lexl_igraph <- function(x) {
  if (requireNamespace("igraph", quietly = TRUE)) {
    edges <- lexl_edges(x)
    vertices <- lexl_vertices(x)
    graph <- igraph::graph_from_data_frame(edges, vertices = vertices)
    igraph::V(graph)$label <- vertices$label
    igraph::V(graph)$token <- vertices$token
    igraph::V(graph)$type <- vertices$type
    graph
  } else {
    stop("lexl_igraph() requires the packages 'igraph'.", call. = FALSE) # nocov
  }
}
