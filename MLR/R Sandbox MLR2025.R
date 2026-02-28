library(readxl)
data <- read_excel("H:/Personal/Stats Analysis/MLR_Predictor_Practice.xlsx")
View(data)  

lm(TFR_Points ~ Player + Team + Opp + Team:Opp, data = data)


x_labs <- levels(factor(data$number))
boxplot(data$TFR_Points ~ data$number, main="Box Plot Number vs TFR_Points", ylab="TFR_Points", las=2, xlab = NULL)


x_labs <- levels(factor(data$Team))
boxplot(data$TFR_Points ~ data$Team , main="Box Plot Team vs TFR_Points", ylab="TFR_Points", las=2, xlab = NULL)

x_labs <- levels(factor(data$Opp))
boxplot(data$TFR_Points ~ data$Opp , main="Box Plot Opp vs TFR_Points", ylab="TFR_Points", las=2, xlab = NULL)


forward <- data$TFR_Points[data$number<9]
back <- data$TFR_Points[data$number>8 & data$number<16]
bench <- data$TFR_Points[data$number>15 & data$number != 24]
dsp <- data$TFR_Points[data$number ==24]

library("vioplot")
boxplot(forward, back, bench, dsp,
        names=c("Forwards", "Backs", "Bench", "DSP"),
        col="gold")

library(dplyr)
data['FBB'] <- case_when(data$number < 9 ~ "Forward",
                         data $number >8 & data$number <16 ~ "Back",
                         data $number >15 & data$number <24 ~ "Bench",
                         data $number ==24 ~ "DSP"
                         )


View(data)

x_labs <- levels(factor(data$FBB))
boxplot(data$TFR_Points ~ data$FBB , main="Box Plot FBB vs TFR_Points", ylab="TFR_Points", las=2, xlab = NULL)

model <- lm(TFR_Points ~ Player + Team + Opp + FBB, data = data)

summary(model)
confint(model)
anova(model)
plot(model)

new_data <- read_excel("H:/Personal/Stats Analysis/MLR2025_AllPlayersMatches2.xlsx")
View(new_data)

data.table::setnames(new_data,'Pos_Cat','FBB')
prediction_intervals <- predict(model,
                                newdata = new_data,
                                interval = "prediction",
                                level = 0.95)

glm(TFR_Points ~ Player + Team + Opp + FBB, data = data)

data$player_factor <- as.factor(data$Player)
data$player_factor
data$team_factor <- as.factor(data$Team)
data$opp_factor <- as.factor(data$Opp)
data$FBB_factor <- as.factor(data$FBB)
glm <- glm(TFR_Points ~ player_factor + team_factor + opp_factor + FBB_factor, data = data)
summary(glm)




durbinWatsonTest(model)

install.packages("gvlma",dependencies = TRUE,repos = 'http://cran.rstudio.com')
library(gvlma)

gvmodel <- gvlma(model)
summary(gvmodel)

vars <- c("TFR_Points", "Player", "Team", "Opp")
ncor <- cor(data[vars], use="pairwise.complete.obs")
corrplot(ncor, method="shade", shade.col=NA, tl.col="black",tl.cex=0.5)


#outlier test
outlierTest(model)
#noted outliers that are statistically significant
#outlier results":
data[c(2703,2556,253,1066,1716,2653,2007,2661,2678,2492),c("Rnd", "Player", "TFR_Points")]



cutoff <- 4/(nrow(data)-length(model$coefficients)-2)
plot(model, which=4, cook.levels=cutoff)
abline(h=cutoff, lty=2, col="red")


influencePlot(model, id.method = "identify")

summary(powerTransform(data[vars]$TFR_Points))
warnings()


library(leaps)

leaps <- regsubsets(TFR_Points ~ Player + Team + Opp + FBB,
                    data = data,
                    nbest = 4)
plot(leaps, scale = "adjr2")



relweights <- function(fit,...){
  R <- cor(fit$model)
  nvar <- ncol(R)
  rxx <- R[2:nvar, 2:nvar]
  rxy <- R[2:nvar, 1]
  svd <- eigen(rxx)
  evec <- svd$vectors
  ev <- svd$values
  delta <- diag(sqrt(ev))
  lambda <- evec %*% delta %*% t(evec)
  lambdasq <- lambda ^ 2
  beta <- solve(lambda) %*% rxy
  rsquare <- colSums(beta ^ 2)
  rawwgt <- lambdasq %*% beta ^ 2
  import <- (rawwgt / rsquare) * 100
  import <- as.data.frame(import)
  row.names(import) <- names(fit$model[2:nvar])
  names(import) <- "Weights"
  import <- import[order(import),1, drop=FALSE]
  dotchart(import$Weights, labels=row.names(import),
           xlab="% of R-Square", pch=19,
           main="Relative Importance of Predictor Variables",
           sub=paste("Total R-Square=", round(rsquare, digits=3)),
           ...)
  return(import)
}





boxplot(data$TFR_Points)
boxplot(data$TFR_Points ~ Player:ind, data.frame(stack(player_factor) , Label = Player))

boxplot(values ~ Label:ind, data.frame(stack(d[-5]) , Label = d$col5))

