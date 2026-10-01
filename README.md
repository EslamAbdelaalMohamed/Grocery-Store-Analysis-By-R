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
