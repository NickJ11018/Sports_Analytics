
library("nflfastR")
library("tidyverse")
library("ggrepel")
library("nflreadr")
library("nflplotR")
library("nflfastR")
library("dplyr")


options(scipen = 9999)

data <- file.choose()
data <- read.csv(data, sep = ",")

data$DSP

summary(lm(DSP ~ FR ,data = data))
chisq.test(table(data$percent_predict, data$Week))

plot(data$DSP, data$FR,
     xlab = "DSP",
     ylab = "FR",
     xlim = c(-1,10),
     ylim = c(-1, 10))


View(data)









