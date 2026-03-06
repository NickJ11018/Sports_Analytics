#Get data ready in mydata
#Ctrl+Shift+H to set working directory
library("readxl")
md <- read_excel("STRESS.xlsx")

View(md)



###
#1#
###
hist(md$STRESS, main = "STRESS", breaks = c(-0.5,0.5,1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.7,9.5), xlab = "STRESS value", ylab = "Percent of values") #maybe NB?

summary(md$STRESS)
mean(md$STRESS)
sd(md$STRESS)^2

qqnorm(md$STRESS)
table(md$STRESS)



###
#2#
###
ols <- lm(STRESS ~ COHES + ESTEEM + GRADES + SATTACH, data = md)
summary(ols)

#md copy
mdc <- md

mdc['ols_std_res'] <- rstandard(ols)
mdc['ols_pred'] <- predict(ols, mdc, type = "response")
mdc['ols_cook_dist'] <- cooks.distance(ols)

print(mdc[mdc$ols_std_res>2, c("ols_std_res", "STRESS", "NEWID")], n=28)

hist(mdc$ols_std_res, main = "Standardized Residuals for OLS model", xlab = "Standardized Residual")
plot(ols_std_res ~ ols_pred, data = mdc, main = "Standardized Residual vs Fitted Values for OLS model", xlab = "Predicted value", ylab = "Standardized Residual")

plot(ols_cook_dist ~ ols_std_res, data = mdc, main = "Cook's Distance vs Standardized Residuals for OLS Model", xlab = "Standardized Residual", ylab = "Cook's Distance")
abline(h = 4/651, lty = 2, col = "gray")
abline(v = 2, lty = 2, col = "gray")
abline(v = -2, lty = 2, col = "gray")


###
#3#
###

#md copy ln
mdcl <- md
mdcl$STRESS <- mdcl$STRESS + 0.00000000001

ols_ln <- lm(log(STRESS) ~ COHES + ESTEEM + GRADES + SATTACH, data = mdcl)
summary(ols_ln)


mdcl['ols_ln_std_res'] <- rstandard(ols_ln)
mdcl['ols_ln_pred'] <- predict(ols_ln, mdcl, type = "response")
mdcl['ols_ln_cook_dist'] <- cooks.distance(ols_ln)


hist(mdcl$ols_ln_std_res, main = "Standardized Residuals for OLS_ln model", xlab = "Standardized Residual")
plot(ols_ln_std_res ~ ols_ln_pred, data = mdcl, main = "Standardized Residual vs Fitted Values for OLS_ln model", xlab = "Predicted value", ylab = "Standardized Residual")

plot(ols_ln_cook_dist ~ ols_ln_std_res, data = mdcl, main = "Cook's Distance vs Standardized Residuals for OLS_ln Model", xlab = "Standardized Residual", ylab = "Cook's Distance")
abline(h = 4/651, lty = 2, col = "gray")
abline(v = 2, lty = 2, col = "gray")
abline(v = -2, lty = 2, col = "gray")


###
#4#
###

#poisson model
summary(pm <- glm(STRESS ~ COHES + ESTEEM + GRADES + SATTACH, family = "poisson", data = md))

1-pchisq(1349.8-1245.4, 650-646)

mdp <- md

mdp['pm_std_res'] <- rstandard(pm)
mdp['pm_pred'] <- predict(pm, mdp, type = "response")
mdp['pm_cook_dist'] <- cooks.distance(pm)


hist(mdp$pm_std_res, main = "Standardized Residuals for Poisson model", xlab = "Standardized Residual")
plot(pm_std_res ~ pm_pred, data = mdp, main = "Standardized Residual vs Fitted Values for Poisson model", xlab = "Predicted value", ylab = "Standardized Residual")

plot(pm_cook_dist ~ pm_std_res, data = mdp, main = "Cook's Distance vs Standardized Residuals for Poisson Model", xlab = "Standardized Residual", ylab = "Cook's Distance")
abline(h = 4/651, lty = 2, col = "gray")
abline(v = 2, lty = 2, col = "gray")
abline(v = -2, lty = 2, col = "gray")


mdp[abs(mdp$pm_std_res) > 2,]


####
#4b#
####

library(MASS)

nb <- glm.nb(STRESS ~ COHES + ESTEEM + GRADES + SATTACH, data = md, link = log)
summary(nb)
mdn <- md

mdn['nb_std_res'] <- rstandard(nb)
mdn['nb_pred'] <- predict(nb, mdn, type = "response")
mdn['nb_cook_dist'] <- cooks.distance(nb)


hist(mdn$nb_std_res, main = "Standardized Residuals for Negative Binomial model", xlab = "Standardized Residual")
plot(nb_std_res ~ nb_pred, data = mdn, main = "Standardized Residual vs Fitted Values for Negative Binomial model", xlab = "Predicted value", ylab = "Standardized Residual")

plot(nb_cook_dist ~ nb_std_res, data = mdn, main = "Cook's Distance vs Standardized Residuals for Negative Binomial Model", xlab = "Standardized Residual", ylab = "Cook's Distance")
abline(h = 4/651, lty = 2, col = "gray")
abline(v = 2, lty = 2, col = "gray")
abline(v = -2, lty = 2, col = "gray")


mdn[mdn$nb_std_res > 2,]




###
#5#
###
mdp$poisson_pred <- fitted(pm)
mdp$mean <- mean(mdp$COHES)
mdp$sd <- sd(md$COHES)

mdp$std.dev <- (mdp$COHES - mdp$mean) / sd(mdp$COHES)

low_COHES <- mdp[mdp$std.dev < -1,]
mid_COHES <- mdp[mdp$std.dev >= -1 & mdp$std.dev < 1,]
high_COHES <- mdp[mdp$std.dev >= 1,]
#106+446+99 = 651


mean(low_COHES$poisson_pred)
mean(high_COHES$poisson_pred)
#2.502785/1.188274


###
#6#
###

AIC(pm)
AIC(nb)
BIC(pm)
BIC(nb)


###
#7#
###
plot(pm$residuals ~ pm$fitted, xlab = "Fitted values", ylab = "Residual", main = "Poisson Model")
sort(pm$residuals)

###
#8#
###
md$y_ind <- case_when(md$STRESS > 0 ~ 1,
                      md$STRESS == 0 ~ 0)

md[, c("STRESS", "y_ind")]

log_model <- glm(y_ind ~ COHES + ESTEEM + GRADES + SATTACH , family= binomial(link='logit'), data = md)

summary(log_model)

md_log <- md
md_log$pred <- predict(log_model,newdata=md_log)
md_log$pred <- case_when( md_log$pred >= 0.5 ~ 1,
                          md_log$pred < 0.5 ~ 0)

mosaicplot(table(md_log$y_ind, md_log$pred), xlab = "Pred", ylab = "y_ind", main = "Y_ind vs Prediction")
table(md_log$y_ind, md_log$pred)
table(md_log$y_ind)


###
#9#
###
md_combined <- md

md_combined$pred <- case_when(md$STRESS > 0 ~ 1,
                              md$STRESS == 0 ~ 0)


#combined poisson
cp <-  glm(STRESS ~ COHES + ESTEEM + GRADES + SATTACH, family = "poisson"
           , data = md_combined[md_combined$y_ind == 1,])
summary(cp)

1-pchisq(415.81-380.26, 429-425)

md_combined[md_combined$y_ind==1,'c_std_res'] <- rstandard(cp)
md_combined[md_combined$y_ind==1,'c_pred'] <- predict(cp, md_combined[md_combined$y_ind==1,], type = "response")
md_combined[md_combined$y_ind==1,'c_cook_dist'] <- cooks.distance(cp)


hist(md_combined$c_std_res, main = "Standardized Residuals for Poisson part of combined model", xlab = "Standardized Residual")
plot(c_std_res ~ c_pred, data = md_combined, main = "Standardized Residual vs Fitted Values for Poisson part of combined model", xlab = "Predicted value", ylab = "Standardized Residual")

plot(c_cook_dist ~ c_std_res, data = md_combined, main = "Cook's Distance vs Standardized Residuals for Poisson part of combined model", xlab = "Standardized Residual", ylab = "Cook's Distance")
abline(h = 4/430, lty = 2, col = "gray")
abline(v = 2, lty = 2, col = "gray")
abline(v = -2, lty = 2, col = "gray")


####
#10#
####
#install.packages("pscl")
library(pscl)

md_zip <- md

zip <- zeroinfl(STRESS ~ COHES + ESTEEM + GRADES + SATTACH, data = md_zip, dist = "poisson")
summary(zip)
#3variables
summary(zip_2 <- zeroinfl(STRESS ~ COHES + ESTEEM + GRADES, data = md_zip, dist = "poisson"))
summary(zip_3 <- zeroinfl(STRESS ~ COHES + ESTEEM + SATTACH, data = md_zip, dist = "poisson"))
summary(zip_4 <- zeroinfl(STRESS ~ COHES + GRADES + SATTACH, data = md_zip, dist = "poisson"))
summary(zip_5 <- zeroinfl(STRESS ~ ESTEEM + GRADES + SATTACH, data = md_zip, dist = "poisson"))
#2variables
summary(zip_6 <- zeroinfl(STRESS ~ COHES + ESTEEM, data = md_zip, dist = "poisson"))
summary(zip_7 <- zeroinfl(STRESS ~ COHES + SATTACH, data = md_zip, dist = "poisson"))
summary(zip_8 <- zeroinfl(STRESS ~ GRADES + SATTACH, data = md_zip, dist = "poisson"))
summary(zip_9 <- zeroinfl(STRESS ~ COHES + GRADES, data = md_zip, dist = "poisson"))
summary(zip_10 <- zeroinfl(STRESS ~ ESTEEM + SATTACH, data = md_zip, dist = "poisson"))
summary(zip_11 <- zeroinfl(STRESS ~ ESTEEM + GRADES, data = md_zip, dist = "poisson"))
#1variable
summary(zip_12 <- zeroinfl(STRESS ~ COHES , data = md_zip, dist = "poisson"))
summary(zip_13 <- zeroinfl(STRESS ~ ESTEEM, data = md_zip, dist = "poisson"))
summary(zip_14 <- zeroinfl(STRESS ~ GRADES, data = md_zip, dist = "poisson"))
summary(zip_15 <- zeroinfl(STRESS ~ SATTACH, data = md_zip, dist = "poisson"))


1-pchisq(logLik(zip)-logLik(zip_2), df = 1)
1-pchisq(logLik(zip)-logLik(zip_3), df = 1)
1-pchisq(logLik(zip)-logLik(zip_4), df = 1)
1-pchisq(logLik(zip)-logLik(zip_5), df = 1)
1-pchisq(logLik(zip)-logLik(zip_6), df = 2)
1-pchisq(logLik(zip)-logLik(zip_7), df = 2)
1-pchisq(logLik(zip)-logLik(zip_8), df = 2)
1-pchisq(logLik(zip)-logLik(zip_9), df = 2)
1-pchisq(logLik(zip)-logLik(zip_10), df = 2)
1-pchisq(logLik(zip)-logLik(zip_11), df = 2)
1-pchisq(logLik(zip)-logLik(zip_12), df = 3)
1-pchisq(logLik(zip)-logLik(zip_13), df = 3)
1-pchisq(logLik(zip)-logLik(zip_14), df = 3)
1-pchisq(logLik(zip)-logLik(zip_15), df = 3)



BIC(zip_4)*AIC(zip_4)
BIC(zip_7)*AIC(zip_7)
BIC(zip_8)*AIC(zip_8)
BIC(zip_9)*AIC(zip_9)
BIC(zip_10)*AIC(zip_10)
BIC(zip_11)*AIC(zip_11)
BIC(zip_12)*AIC(zip_12)
BIC(zip_13)*AIC(zip_13)
BIC(zip_14)*AIC(zip_14)
BIC(zip_15)*AIC(zip_15)




md_new <- md

zip <- zeroinfl(STRESS ~ COHES + ESTEEM + GRADES + SATTACH, data = md_zip, dist = "negbin")
summary(zip)
#3variables
summary(zip_2 <- zeroinfl(STRESS ~ COHES + ESTEEM + GRADES, data = md_zip, dist = "negbin"))
summary(zip_3 <- zeroinfl(STRESS ~ COHES + ESTEEM + SATTACH, data = md_zip, dist = "negbin"))
summary(zip_4 <- zeroinfl(STRESS ~ COHES + GRADES + SATTACH, data = md_zip, dist = "negbin"))
summary(zip_5 <- zeroinfl(STRESS ~ ESTEEM + GRADES + SATTACH, data = md_zip, dist = "negbin"))
#2variables
summary(zip_6 <- zeroinfl(STRESS ~ COHES + ESTEEM, data = md_zip, dist = "negbin"))
summary(zip_7 <- zeroinfl(STRESS ~ COHES + SATTACH, data = md_zip, dist = "negbin"))
summary(zip_8 <- zeroinfl(STRESS ~ GRADES + SATTACH, data = md_zip, dist = "negbin"))
summary(zip_9 <- zeroinfl(STRESS ~ COHES + GRADES, data = md_zip, dist = "negbin"))
summary(zip_10 <- zeroinfl(STRESS ~ ESTEEM + SATTACH, data = md_zip, dist = "negbin"))
summary(zip_11 <- zeroinfl(STRESS ~ ESTEEM + GRADES, data = md_zip, dist = "negbin"))
#1variable
summary(zip_12 <- zeroinfl(STRESS ~ COHES , data = md_zip, dist = "negbin"))
summary(zip_13 <- zeroinfl(STRESS ~ ESTEEM, data = md_zip, dist = "negbin"))
summary(zip_14 <- zeroinfl(STRESS ~ GRADES, data = md_zip, dist = "negbin"))
summary(zip_15 <- zeroinfl(STRESS ~ SATTACH, data = md_zip, dist = "negbin"))

BIC(zip_2)*AIC(zip_2)
BIC(zip_3)*AIC(zip_3)
BIC(zip_4)*AIC(zip_4)
BIC(zip_5)*AIC(zip_5)
BIC(zip_6)*AIC(zip_6)
BIC(zip_7)*AIC(zip_7)
BIC(zip_8)*AIC(zip_8)
BIC(zip_9)*AIC(zip_9)
BIC(zip_10)*AIC(zip_10)
BIC(zip_11)*AIC(zip_11)
BIC(zip_12)*AIC(zip_12)
BIC(zip_13)*AIC(zip_13)
BIC(zip_14)*AIC(zip_14)
BIC(zip_15)*AIC(zip_15)

1-pchisq(logLik(zip)-logLik(zip_2), df = 1)
1-pchisq(logLik(zip)-logLik(zip_3), df = 1)
1-pchisq(logLik(zip)-logLik(zip_4), df = 1)
1-pchisq(logLik(zip)-logLik(zip_5), df = 1)
1-pchisq(logLik(zip)-logLik(zip_6), df = 2)
1-pchisq(logLik(zip)-logLik(zip_7), df = 2)
1-pchisq(logLik(zip)-logLik(zip_8), df = 2)
1-pchisq(logLik(zip)-logLik(zip_9), df = 2)
1-pchisq(logLik(zip)-logLik(zip_10), df = 2)
1-pchisq(logLik(zip)-logLik(zip_11), df = 2)
1-pchisq(logLik(zip)-logLik(zip_12), df = 3)
1-pchisq(logLik(zip)-logLik(zip_13), df = 3)
1-pchisq(logLik(zip)-logLik(zip_14), df = 3)
1-pchisq(logLik(zip)-logLik(zip_15), df = 3)