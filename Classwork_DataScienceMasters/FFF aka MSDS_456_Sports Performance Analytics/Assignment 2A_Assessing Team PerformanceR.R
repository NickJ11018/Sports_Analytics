install.packages("nflfastR")
install.packages("tidyverse", type = "binary")
install.packages("ggrepel", type = "binary")
install.packages("nflreadr", type = "binary")
install.packages("nflplotR", type = "binary")


library("nflfastR")
library("tidyverse")
library("ggrepel")
library("nflreadr")
library("nflplotR")
library("nflfastR")
library("dplyr")


options(scipen = 9999)

###Step 1###
#install.packages("Lahman")
#library("Lahman")

##https://github.com/bacook17/CS109_baseball/blob/master/data/lahman/Teams.csv

#data <- file.choose()
#data <- read.csv(data, sep = ",")

teams <- Lahman::Teams
tail(teams)


myteams <- subset(teams, yearID >= 2013)[,c("teamID", "yearID", "lgID", "G", "W", "L", "R", "RA")]


myteams$RD <- myteams$R-myteams$RA
myteams$Wpct <- myteams$W/myteams$G

myteams


plot(myteams$RD, myteams$Wpct, xlab = "Run differential", ylab = "Winning percentage")


linfit <- lm(Wpct ~ RD, data = myteams)

linfit


abline(a = coef(linfit)[1], b = coef(linfit)[2], lwd = 2)



myteams$linWpct <- predict(linfit)
myteams$linResiduals <- residuals(linfit)


plot(subset(myteams$RD, myteams$teamID == 'MIN'), subset(myteams$linResiduals, myteams$teamID == 'MIN'),
     xlab = "Run differential",
     ylab = "Residual",
     ylim = c(-.09, .09))
abline(h = 0, lty = 3) #dashed
points(c(68,88), c(0.0749, -0.0733), pch = 19)
text(68, 0.0749, "LAA '08", pos=4, cex = 0.8)
text(88, -0.0733, "CLE '06", pos=4, cex = 0.8)



subset(myteams, teamID == 'MIN')




mean(myteams$linResiduals)
linRMSE <- sqrt(mean(myteams$linResiduals ^ 2))
linRMSE

nrow(subset(myteams, abs(linResiduals) < linRMSE))/nrow(myteams) #~66% actually closer to 0.747 so quite compact
nrow(subset(myteams, abs(linResiduals) < 2*linRMSE))/nrow(myteams) #checks out, ~95% @ 0.95



myteams$pytWpct <- with(myteams, R^2 / (R^2 + RA^2))

myteams$pytResiduals <- with(myteams, Wpct - pytWpct)

pytRMSE <- sqrt(mean(myteams$pytResiduals^2))
pytRMSE #from 0.03123044 to 0.02782048




#Figuring out the exponent

myteams$logWratio <- log(myteams$W / myteams$L)
myteams$logRratio <- log(myteams$R / myteams$RA)

pytFit <- lm(logWratio ~ 0 + logRratio, data = myteams)

pytFit #surprisingly low at 1.77



#Other teams
nrow(subset(subset(myteams, pytResiduals > 0), teamID == 'MIN'))

nrow(subset(myteams, lgID == 'AL'))









#Part 2
batting <- Lahman::Batting[, c("playerID", "yearID", "teamID", "G", "AB", "R", "H", "X2B", "X3B", "HR", "RBI", "SB", "CS", "BB", "SO", "IBB", "HBP", "SH", "SF", "GIDP")]


tail(subset(batting, teamID == 'MIN'))

batting %>%
  filter(teamID == 'MIN', yearID == '2022') %>%
  arrange(-AB)


















