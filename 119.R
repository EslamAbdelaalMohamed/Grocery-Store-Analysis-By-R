# Load necessary libraries
# Load necessary libraries
library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(arules)
library(arulesViz)
library(gridExtra)

install.packages(c("tidyverse", "ggplot2", "shiny", "arules", "cluster"))
library(c("tidyverse", "ggplot2", "shiny", "arules", "cluster"))
dataset <- grc_1_
summary(dataset)
dataset<- na.omit(dataset)
duplicated(dataset)
sum(duplicated(dataset))
distinct(dataset)
sum(duplicated(dataset))
dataset<-unique(dataset)
sum(duplicated(dataset))
dataset<-data_frame(dataset)


# Define the User Interface (UI)
ui <- dashboardPage(
  dashboardHeader(title = "Grocery Store Analysis"),
  dashboardSidebar(
    sidebarMenu(
      fileInput("dataset", "Upload Dataset"),
      numericInput("clusters", "Number of Clusters", min = 2, max = 4, value = 3),
      numericInput("min_support", "Minimum Support", min = 0.001, max = 1, value = 0.1),
      numericInput("min_confidence", "Minimum Confidence", min = 0.001, max = 1, value =
                     0.5),
      actionButton("analyze", "Analyze Data")
    )
  ),
  dashboardBody(
    fluidRow(
      column(width = 4,
             box(title = "Visualizations", width = NULL, plotOutput("visualization_dashboard"))
      ),
      column(width = 4,
             box(title = "Clustering", width = NULL, tableOutput("cluster_results"))
      ),
      column(width = 4,
             box(title = "Association Rules", width = NULL, tableOutput("association_rules_table"))
      )
    )
  )
)
# Define the Server logic
server <- function(input, output, session) {
  # Reactive function to process uploaded data
  data_processed <- reactive({
    req(input$dataset) # Ensure a file is uploaded
    df <- read.csv(input$dataset$datapath, stringsAsFactors = FALSE)
    return(df)
  })
  # Render visualizations
  output$visualization_dashboard <- renderPlot({
    req(data_processed())
    df <- data_processed()
    # Plot 1: Cash vs Credit sales
    p1 <- ggplot(df, aes(x = paymentType, y = total)) +
      geom_bar(stat = "summary", fun = "sum", fill = "steelblue") +
      labs(title = "Comparison of Cash and Credit Sales")
    # Plot 2: Age vs Spending
    p2 <- ggplot(df, aes(x = age, y = total)) +
      geom_point(alpha = 0.6, color = "darkgreen") +
      geom_smooth(method = "lm", color = "red") +
      labs(title = "Relationship Between Age and Spending")
    # Plot 3: Total spending by city
    p3 <- df %>%
      group_by(city) %>%
      summarise(total_city_spending = sum(total)) %>%
      arrange(desc(total_city_spending)) %>%
      ggplot(aes(x = reorder(city, total_city_spending), y = total_city_spending)) +
      geom_bar(stat = "identity", fill = "orange") +
      coord_flip() +
      labs(title = "Total Spending by City")
    # Plot 4: Distribution of total spending
    p4 <- ggplot(df, aes(x = total)) +
      geom_histogram(bins = 20, fill = "purple", alpha = 0.7) +
      labs(title = "Distribution of Total Spending")
    # Arrange plots
    grid.arrange(p1, p2, p3, p4, ncol = 2)
  })
  # Perform clustering
  output$cluster_results <- renderTable({
    req(data_processed())
    df <- data_processed()
    # Prepare data for clustering
    cluster_data <- df %>%
      select(age, total) %>%
      scale()
    # Apply k-means clustering
    set.seed(123)
    clusters <- kmeans(cluster_data, centers = input$clusters, iter.max = 10, nstart = 10)
    # Add cluster information to the data
    df$cluster <- clusters$cluster
    # Return a summary table
    df %>% select(customer, age, total, cluster) %>% arrange(cluster)
  })
  # Generate association rules
  output$association_rules_table <- renderTable({
    req(data_processed())
    df <- data_processed()
    # Convert data into transaction format
    transactions <- as(split(df$items, df$customer), "transactions")
    # Generate association rules
    rules <- apriori(
      transactions,
      parameter = list(
        supp = input$min_support,
        conf = input$min_confidence,
        maxlen = 3, # Limit rule length
        maxtime = 30 # Set a maximum execution time
      )
    )
    # Convert rules to a data frame
    rules_df <- data.frame(
      Rule = labels(rules),
      Support = quality(rules)$support,
      Confidence = quality(rules)$confidence,
      Lift = quality(rules)$lift
    )
    # Display the top 10 rules
    head(rules_df, 10)
  })
}
# Launch the Shiny app
shinyApp(ui, server)