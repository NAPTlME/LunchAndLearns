# for visualization and classification of clusters from bertTopic > tsne > hdbscan

library(dplyr)
library(stringr)
library(jsonlite)
library(lubridate)
library(ggplot2)
library(shiny)
library(shinydashboard)
library(wordcloud2)

setwd("~/GitHub/LunchAndLearns/TextClassificationViaBertTopic")
source("../../Linguistic-Feature-Limiting-in-Topic-Modelling/nlpFx.R")

#### import ####
txt = read.csv("general.csv")[,-1]
df = read.csv("generalTsneDf3.csv")[,-1] %>% 
  mutate(labels = labels + 1, # adjusting for 1-based indexing in R
         txt = txt, 
         labels = as.factor(labels),
         clusterLabel = NA)

# sampleDtm = GetDtm(txt[1:3])
# sampleDtm
# View(as.matrix(sampleDtm))
# 
# sampleTfIdf = GetTfIdf(sampleDtm)
# View(as.matrix(sampleTfIdf))

icTfIdf = innerClusterTfIdf(GetDtm(txt), clust = as.numeric(as.character(df$labels)))


#### explore ####

ggplot(df) +
  geom_point(aes(x,y, color = labels))

#### Shiny Dashboard ####

#todo: add in most important terms

ui = dashboardPage(
  dashboardHeader(title = "Clustered Documents"),
  dashboardSidebar(
    sidebarMenu(
      fluidRow(
        selectInput("inputCluster", "Cluster", sort(unique(df$labels)), selected = 0)
      ),
      fluidRow(
        textInput("inputLabel", NULL, value = "", placeholder = NULL)
      ),
      fluidRow(
        actionButton("inputBtn", "Set Label")
      )
    )
  ),
  dashboardBody(
    fluidRow(
      box(plotOutput("plot1", width = 800, height = 500)),
      box(wordcloud2Output("wc1", width = 600, height = 500))
    ),
    fluidRow(
      tableOutput("tbl1")
    )
  )
)

server = function(input, output, session) {
  clusterSel = reactive({
    input$inputCluster
  })
  
  observeEvent(input$inputBtn, {
    lbl = input$inputLabel
    cluster = clusterSel()
    if (cluster != "0") {
      df$clusterLabel[df$labels == cluster] <<- lbl
      updateTextInput(session, "inputLabel", label = NULL, value = "", placeholder = lbl)
    } else {
      updateTextInput(session, "inputLabel", label = NULL, value = "", placeholder = "")
    }
    
  })
  
  observe({
    cluster = clusterSel()
    lbl = df$clusterLabel[df$labels == cluster][1]
    if (is.na(lbl)) {
      updateTextInput(session, "inputLabel", label = NULL, value = "", placeholder = "")
    } else {
      updateTextInput(session, "inputLabel", label = NULL, value = "", placeholder = lbl)
    }
  })
  
  output$plot1 = renderPlot({
    cluster = clusterSel()
    print(cluster)
    captionText = paste0("Total Records: ", nrow(df))
    p = ggplot() +
      geom_point(data = df %>% filter(labels == "0"), aes(x, y), color = "grey72", size = 1)
    if(cluster == "0"){
      p = p +
        geom_point(data = df %>% filter(labels != "0"), aes(x, y, color = labels), size = 1)
    } else {
      p = p + 
        geom_point(data = df %>% filter(labels != "0", labels != cluster), aes(x, y), color = "grey72", size = 1) +
        geom_point(data = df %>% filter(labels == cluster), aes(x, y, color = labels), size = 1)
      captionText = paste0("Records in Cluster ", cluster, ": ", nrow(df %>% filter(labels == cluster)))
    }
    p +
      labs(caption = paste0())
  })
  output$tbl1 = renderTable({
    cluster = clusterSel()
    if(cluster == "0"){
      NULL
    } else {
      df %>% filter(labels == cluster)
    }
  })
  output$wc1 = renderWordcloud2({
    cluster = clusterSel()
    if (cluster != "0") {
      row = icTfIdf[as.numeric(cluster) + 1,]
      freqDf = data.frame(word = names(row), freq = as.numeric(row)) %>% 
        # get top 50 only
        arrange(-freq) %>%
        filter(row_number() <= 50)
      wordcloud2::wordcloud2(freqDf)
    }
  })
}

shinyApp(ui, server)