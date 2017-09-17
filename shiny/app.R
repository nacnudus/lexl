library(lexl)

shiny::shinyApp(
  ui = shiny::fluidPage(
    shiny::titlePanel(shiny::HTML("Demo of <b><a href=\"https://nacnudus.github.io/tidyxl/\">tidyxl</a></b>::<b><a href=\"https://nacnudus.github.io/tidyxl/articles/smells.html\">lexl()</a></b>: Tokenize Excel formulas with R")),
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
    output$call <- shiny::renderText(paste0("<pre>library(tidyxl)\n",
                                            "parse_tree <- lex_xl(\"",
                                              input$formula,
                                            "\")\n",
                                            "parse_tree\n",
                                            "plot(parse_tree)"))
    output$tree <- shiny::renderTable({parse_tree()})
    output$plot <- shiny::renderPlot({
      plot(lex_lx(input$formula))
    })
  })

