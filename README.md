# Grocery Store Analysis – Project Report

## 1. Project Overview

This project develops an interactive **R Shiny dashboard** for analyzing grocery store customer transaction data.

The project combines three main analytical tasks:

1. **Exploratory Data Analysis (EDA)** through visualizations.
2. **Customer Clustering** using the K-Means algorithm.
3. **Market Basket Analysis** using Association Rule Mining with the Apriori algorithm.

The dashboard allows the user to upload a CSV dataset and interactively control the number of clusters, minimum support, and minimum confidence.

---

## 2. Project Objectives

The main objectives are:

- Understand the structure of the grocery store dataset.
- Remove missing and duplicate records before analysis.
- Visualize sales behavior using several plots.
- Segment customers based on **age** and **total spending**.
- Discover relationships between products purchased by customers.
- Provide the analysis through an interactive Shiny dashboard.

---

## 3. Technologies and Libraries

The implementation is written in **R** and uses the following packages:

- `shiny` – building the interactive web application.
- `shinydashboard` – creating the dashboard layout.
- `dplyr` – data manipulation.
- `ggplot2` – data visualization.
- `arules` – association rule mining.
- `arulesViz` – association-rule visualization support.
- `gridExtra` – arranging multiple plots.
- `cluster` – clustering-related functionality.

---

## 4. Data Preparation

The original script performs several basic data-cleaning operations:

```r
summary(dataset)

dataset <- na.omit(dataset)

sum(duplicated(dataset))

distinct(dataset)

dataset <- unique(dataset)

dataset <- data_frame(dataset)
```

### Data-cleaning logic

### Missing values

`na.omit()` removes observations containing missing values.

### Duplicate records

The script checks duplicates using:

```r
sum(duplicated(dataset))
```

It then removes duplicated rows using:

```r
dataset <- unique(dataset)
```

### Important Note

The supplied script contains some implementation issues that should be corrected before treating it as a final production-ready application:

- `dataset <- grc_1_` assumes that an object named `grc_1_` already exists.
- `library(c("tidyverse", ...))` is not valid standard R syntax for loading multiple packages.
- `install.packages()` should normally not be executed every time the application starts.
- `data_frame()` is deprecated; `data.frame()` or a modern tibble approach is preferred.
- The dashboard itself reads the uploaded CSV through `read.csv()`, so the initial `dataset` object is not actually required by the Shiny upload workflow.

---

## 5. Interactive Dashboard

The dashboard is created using `shinydashboard`.

The user interface contains:

- A **CSV file upload** control.
- A numeric input for the number of clusters.
- A numeric input for minimum support.
- A numeric input for minimum confidence.
- An **Analyze Data** button.

The dashboard displays three main areas:

1. Visualizations.
2. Clustering results.
3. Association rules.

The uploaded file is processed reactively:

```r
data_processed <- reactive({
    req(input$dataset)
    df <- read.csv(input$dataset$datapath, stringsAsFactors = FALSE)
    return(df)
})
```

This means that the analysis depends on the dataset uploaded by the user.

---

# 6. Exploratory Data Analysis

The dashboard generates four visualizations.

## 6.1 Cash vs Credit Sales

The first plot compares the total sales amount for different payment types.

```r
ggplot(df, aes(x = paymentType, y = total)) +
    geom_bar(stat = "summary", fun = "sum") +
    labs(title = "Comparison of Cash and Credit Sales")
```

### Interpretation

The chart can be used to determine which payment method contributes the largest total sales value.

---

## 6.2 Age vs Spending

The second plot investigates the relationship between customer age and total spending.

```r
ggplot(df, aes(x = age, y = total)) +
    geom_point(alpha = 0.6) +
    geom_smooth(method = "lm") +
    labs(title = "Relationship Between Age and Spending")
```

The scatter plot shows individual observations, while the linear regression line provides a simple indication of the overall relationship.

### Interpretation

If the regression line has a positive slope, spending tends to increase with age. If it has a negative slope, spending tends to decrease with age. A nearly horizontal line suggests a weak linear relationship.

---

## 6.3 Total Spending by City

The third visualization aggregates spending by city.

```r
df %>%
    group_by(city) %>%
    summarise(total_city_spending = sum(total)) %>%
    arrange(desc(total_city_spending))
```

The results are displayed as a horizontal bar chart.

### Interpretation

This visualization identifies cities with the highest and lowest total spending and can support geographic sales analysis.

---

## 6.4 Distribution of Total Spending

The fourth plot is a histogram of customer transaction totals.

```r
ggplot(df, aes(x = total)) +
    geom_histogram(bins = 20) +
    labs(title = "Distribution of Total Spending")
```

### Interpretation

The histogram helps identify the shape of the spending distribution, including concentration, spread, skewness, and potential extreme observations.

---

# 7. Customer Segmentation Using K-Means

The project applies **K-Means clustering** using two variables:

- `age`
- `total`

The variables are standardized before clustering:

```r
cluster_data <- df %>%
    select(age, total) %>%
    scale()
```

### Why standardization?

Age and spending may have very different numerical scales. Standardization prevents the variable with the larger scale from dominating the Euclidean distance used by K-Means.

The clustering algorithm is then applied:

```r
set.seed(123)

clusters <- kmeans(
    cluster_data,
    centers = input$clusters,
    iter.max = 10,
    nstart = 10
)
```

### Parameters

- `centers` = number of customer groups selected by the user.
- `iter.max = 10` = maximum number of iterations.
- `nstart = 10` = K-Means is initialized 10 times and the best solution is selected.
- `set.seed(123)` makes the result reproducible.

The cluster label is added to the dataset:

```r
df$cluster <- clusters$cluster
```

The dashboard then displays:

- Customer ID/name.
- Age.
- Total spending.
- Cluster assignment.

### Interpretation

Each cluster represents a group of customers with relatively similar standardized age and spending characteristics.

For example, depending on the dataset, one cluster may represent younger/lower-spending customers while another may represent older/higher-spending customers.

The exact interpretation must be based on the actual cluster centers and dataset results.

---

# 8. Association Rule Mining

The project also performs **Market Basket Analysis**.

The transaction data is converted into the transaction format required by the `arules` package:

```r
transactions <- as(
    split(df$items, df$customer),
    "transactions"
)
```

Each customer is treated as a transaction containing the items they purchased.

The Apriori algorithm is then applied:

```r
rules <- apriori(
    transactions,
    parameter = list(
        supp = input$min_support,
        conf = input$min_confidence,
        maxlen = 3,
        maxtime = 30
    )
)
```

## Main Parameters

### Support

Support measures how frequently an item combination appears in the transactions.

A higher minimum support produces fewer but more frequent rules.

### Confidence

Confidence measures how often the consequent is purchased when the antecedent is purchased.

A higher minimum confidence produces stronger rules.

### Lift

The project extracts lift as an additional measure:

```r
quality(rules)$lift
```

Lift compares the observed co-occurrence of items with what would be expected if the items were independent.

- Lift > 1: positive association.
- Lift ≈ 1: weak/no association.
- Lift < 1: negative association.

---

# 9. Association Rule Output

The generated rules are converted into a data frame containing:

- Rule
- Support
- Confidence
- Lift

Only the first 10 rules are displayed:

```r
head(rules_df, 10)
```

### Interpretation

A useful rule should not be evaluated using confidence alone. Support and lift should also be considered.

For example, a rule with high confidence but extremely low support may describe only a very small number of customers.

---

# 10. Overall Analytical Workflow

The complete workflow can be summarized as:

**CSV Dataset**

↓

**Data Upload**

↓

**Data Cleaning**

- Missing values
- Duplicate records

↓

**Exploratory Data Analysis**

- Payment type vs sales
- Age vs spending
- City spending
- Spending distribution

↓

**Customer Segmentation**

- Select age and total
- Standardize variables
- Apply K-Means
- Display cluster assignments

↓

**Market Basket Analysis**

- Group items by customer
- Convert to transactions
- Apply Apriori
- Calculate support, confidence, and lift

↓

**Interactive Dashboard**

---

# 11. Strengths of the Project

The project has several useful characteristics:

- Combines multiple Data Science techniques in one application.
- Uses an interactive dashboard instead of static analysis only.
- Allows the user to change clustering and association-rule parameters.
- Uses standard R Data Science libraries.
- Provides both customer segmentation and product-association analysis.
- Includes basic data cleaning before analysis.

---

# 12. Limitations and Recommended Improvements

The supplied implementation can be improved in several areas.

## 12.1 Data Validation

Before analysis, the application should verify that required columns exist:

- `paymentType`
- `total`
- `age`
- `city`
- `customer`
- `items`

It should also check whether numeric variables are actually numeric.

## 12.2 Better Missing-Value Handling

`na.omit()` removes complete rows containing missing values. In a real analytical project, it may be preferable to investigate the missingness first and decide whether deletion or imputation is appropriate.

## 12.3 Better Clustering Evaluation

The current application lets the user select the number of clusters from 2 to 4, but it does not evaluate the selected value.

A future version could use:

- Elbow Method.
- Silhouette Score.
- Cluster visualization.

## 12.4 More Useful Cluster Summary

Instead of displaying only customer-level assignments, the dashboard could show cluster summaries such as:

- Number of customers.
- Average age.
- Average spending.
- Minimum spending.
- Maximum spending.

This would make business interpretation easier.

## 12.5 Association Rule Filtering

The application currently displays the first 10 rules rather than explicitly ranking them by lift, confidence, or another business criterion.

A better approach would be to sort rules by a chosen metric and allow the user to filter them.

## 12.6 Dashboard Interaction

The `Analyze Data` button is defined in the UI, but the current server logic does not use `input$analyze` as a trigger. The analysis is instead reactive to the uploaded dataset and parameter inputs.

If the intended behavior is to analyze only after pressing the button, the reactive logic should be redesigned around an event trigger.

---

# 13. Conclusion

This project demonstrates an end-to-end grocery store analytics application using R and Shiny.

The application combines:

- Data cleaning.
- Exploratory visualization.
- K-Means customer segmentation.
- Apriori association rule mining.
- Interactive dashboard development.

From a Data Science perspective, the project demonstrates how descriptive analytics, unsupervised learning, and association analysis can be integrated into a single practical application.

The main improvement required before final deployment is strengthening data validation, clustering evaluation, rule ranking, and the Shiny application's reactive workflow.

---

## 14. Source

This report is based on the supplied R project script:

`119.R`

No external dataset values or numerical analytical results were assumed because the supplied script does not include the actual dataset contents.
