library(lexl)
library(ggraph)

shiny::shinyApp(
  ui = shiny::fluidPage(
    shiny::titlePanel(shiny::HTML("Demo of <b><a href=\"https://nacnudus.github.io/lexl/\">lexl</a></b>::<b><a href=\"https://nacnudus.github.io/lexl/articles/lex-xl.html\">lexl()</a></b>: Tokenize Excel formulas with R")),
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        width = 3,
        shiny::textAreaInput("formula",
                             "Formula",
                             "MIN(3,MAX(2,A1))",
                             resize = "vertical"),
        shiny::htmlOutput("call"),
        shiny::tableOutput("tree")
      ),
      shiny::mainPanel(
        shiny::plotOutput("plot")
      )
    )
  ),
  server = function(input, output) {
    parse_tree <- shiny::reactive({
      lex_xl(input$formula)
    })
    output$call <- shiny::renderText(paste0("<pre>library(lexl)\n",
                                            "parse_tree <- lex_xl(\"",
                                              input$formula,
                                            "\")\n",
                                            "parse_tree\n",
                                            "plot(parse_tree)"))
    output$tree <- shiny::renderTable({parse_tree()})
    output$plot <- shiny::renderPlot({
      plot(lex_xl(input$formula))
    })
  })

