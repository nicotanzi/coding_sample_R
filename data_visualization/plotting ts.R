###########################################
#####   PLOTTING TIME SERIES WITH R   #####
###########################################

#---- Set up ----

# Libraries
library(xts)
library(lubridate)
library(dplyr)
library(reshape)
library(ggplot2)
library(hrbrthemes)
library(TSstudio)

# Data examples
data(USgas) # ts (time series)
data("Coffee_Prices") # mts (multiple time series)
data("Michigan_CS") # xts (extended time series)

#---- Base ----
# https://rpubs.com/Sergio_Garcia/visualizing_time_series_r
# Single TS
plot(USgas) 

# Multiple TS
plot(Coffee_Prices) # multiple plots

plot(Coffee_Prices[,1]) 
lines(Coffee_Prices[,2], col = "red") # single plot

plot(Michigan_CS)

#---- TS Studio ----
# https://cran.r-project.org/web/packages/TSstudio/vignettes/Plotting_Time_Series.html
library(TSstudio)

## Example 1: Single time series
ts_info(USgas) # quick data overview
ts_plot(USgas) # quick time series plot
ts_plot(USgas,
        title = "US Monthly Natural Gas Consumption",
        Xtitle = "Time",
        Ytitle = "Billion Cubic Feet",
        slider = TRUE) # Plot with slider bar

## Example 2: Multiple time series
ts_info(Coffee_Prices) # mts (multiple time series)

ts_plot(Coffee_Prices) # single plot
ts_plot(Coffee_Prices, type = "multiple") # multiple plots

## Example 3: Non standard time series data (xts and zoo)
ts_info(Michigan_CS) #xts object
# The main advantege of xts and zoo is that
# they allow us to work with irregular time intervals
# Although this is a xts example, it has a regular time interval (monthly)
ts_plot(Michigan_CS)


#---- ggplot2 ----
# Allows for more possibilities, but harder to use
# Input must be dataframe

## Example 1 - Single Time Series
USgas_df <- ts_to_prophet(USgas)

# Standard
ggplot(USgas_df, aes(x=ds, y=y)) +
  geom_line()

# More details
ggplot(USgas_df, aes(x=ds, y=y))  +
  geom_line( color="#69b3a2", size=0.9, alpha=0.9) +
  theme_ipsum() +
  theme(axis.text.x=element_text(angle=60, hjust=1)) +
  xlab("") + ylab("Amount") +
  ggtitle("Evolution of US gas")

## Example 2 - Multiple Time Series

# From mts to dataframe
Coffee_Prices_df_1 <- ts_to_prophet(Coffee_Prices[,1])
Coffee_Prices_df_2 <- ts_to_prophet(Coffee_Prices[,2])
Coffee_Prices_df <- cbind(Coffee_Prices_df_1,Coffee_Prices_df_2[,2])
colnames(Coffee_Prices_df) <- c("Date", colnames(Coffee_Prices))

# Applying long format to the dataframe
Coffee_Prices_df_long <- melt(Coffee_Prices_df, id.vars = "Date")

ggplot(Coffee_Prices_df_long, aes(x = Date, y = value, color = variable)) +
  geom_line()

