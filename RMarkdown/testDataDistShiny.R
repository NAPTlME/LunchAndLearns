library(shiny)
library(ggplot2)

ui = fluidPage(
  sidebarLayout(
    sidebarPanel(
      sliderInput("sliderScale1", label = "Scale_1", value = 1, min = 0.1, max = 2, step = 0.1),
      br(),
      sliderInput("sliderScale2", label = "Scale_2", value = 0.6, min = 0.1, max = 2, step = 0.1),
      br(),
      sliderInput("sliderN", label = "Number of observations", value = 500, min = 100, max = 500000)
    ),
    mainPanel(
      column(plotOutput("pFx"), width = 6),
      column(plotOutput("pDist"), width = 6)
    )
  )
)

server = function(input, output) {
  output$pFx = renderPlot({
    lambda_1 = 1/input$sliderScale1
    lambda_2 = 1/input$sliderScale2
    tmp = curve(lambda_1 * exp(-lambda_1 * (1 - (lambda_2 * exp(-lambda_2 * x)))), from = 0, to = 50)
    ggplot(data.frame(tmp)) + 
      geom_line(aes(x, y))
  })
  
  output$pDist = renderPlot({
    lambda_1 = 1/input$sliderScale1
    z = rexp(input$sliderN, input$sliderScale2)
    vals = ceiling(lambda_1 * exp(-lambda_1 * (1 - z)))
    ggplot(data.frame(vals = vals)) + 
      geom_histogram(aes(vals))
  })
}

shinyApp(ui, server)