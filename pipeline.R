### Pipeline to run PCA annual publication
# clear environment
rm(list = ls())

# source functions
# this is only a temporary step until all functions are built into packages
source("./functions/functions.R")

# 1. Setup
#install and library packages
install.packages("logr")

library(logr)

#set up logging
lf <- log_open("Y:/Official Stats/PCA/log/pca_log.log")
