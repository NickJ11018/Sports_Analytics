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

#https://github.com/nflverse/nflverse-data/releases/download/pbp/play_by_play_2023.csv

data <- file.choose()
data <- read.csv(data, sep = ",")


View(head(data %>% filter(game_id == '2023_01_ARI_WAS'), n = 1000))

###Step 2###
#max(data$total_home_score to data$total_away_score)
#group by game_id
#case where home_score > away_score then winner is 

###Final score of each game###
final_scores <- data %>%
  select(game_id, home_team, away_team, total_home_score, total_away_score) %>%
  group_by(game_id) %>%
  reframe(home_team, away_team, final_home_score = max(total_home_score), final_away_score = max(total_away_score)) 
  
final_scores <- distinct(final_scores)

###Winning team to match to posteam later###
winner <- final_scores %>%
  mutate(winner = case_when(
    final_home_score > final_away_score ~ home_team,
    final_home_score < final_away_score ~ away_team,
    TRUE ~ 'TIE') #no tie games this year
    )



###Join back whether posteam wins###
pos_winner <- data %>%
  full_join(winner, join_by(game_id)) %>%
  select(game_id, drive, home_team.x, away_team.x, posteam, winner) %>%
  mutate(poswins = as.factor(case_when(
  posteam == winner ~ 'Yes',
  TRUE ~ 'No'))
  ) 

View(pos_winner)
#class(pos_winner$poswins) #factorized

View(head(pos_winner))


###Here we pull all details we care about###

play_types_full <- distinct(data %>% select(play_type))
play_types_full
play_types <- play_types_full[c(2:5,7:10),]
play_types

final_table <- data %>%
  filter(!is.na(drive), play_type %in% play_types ) %>%
  left_join(pos_winner, by = c('game_id' = 'game_id', 'drive' = 'drive')) %>%
  mutate(Qtr = as.factor(qtr), Down = as.factor(down)) %>%
  select(game_id, drive, home_team, away_team, posteam.x, yardline_100, Down, ydstogo, score_differential, Qtr, game_seconds_remaining, time, poswins, home_wp)

View(distinct(final_table))


###Test/train split###

#80% of the sample size
sample_size <- floor(0.80 * nrow(final_table))
set.seed(123)
train_ind <- sample(seq_len(nrow(final_table)), size = sample_size)


train_set <- final_table[train_ind, ]
test_set <- final_table[-train_ind, ]
#View(head(train_set))


#Linear model

model1 = glm(poswins ~ Qtr + Down + ydstogo + game_seconds_remaining + yardline_100 + score_differential, train_set, family = "binomial")
  
summary(model1)



#Prediction

pred1 = predict.glm(model1, train_set, type = "response")

train = cbind(train_set,pred1)

#--our model confusion
# setting the cut-off probablity
classify50 <- ifelse(test_set$home_wp > 0.5,"Yes","No")

# ordering the levels
classify50 <- ordered(classify50, levels = c("Yes", "No"))
test_set$default <- ordered(test_set$poswins, levels = c("Yes", "No"))



# confusion matrix
cm <- table(Predicted = classify50, Actual = test_set$default)
cm
#--




View(head(train))

#Flip so only home team win %
train = mutate(train_set, pred1h = ifelse(posteam.x == home_team, pred1, 1-pred1))


#comparing to home_wp
ggplot(filter(train, game_id == "2023_15_PHI_SEA"), aes(x=game_seconds_remaining)) + ggtitle("Home Win Probability (red) vs Model HWP (blue) for Week 15 Seahawks vs Eagles") + geom_line(aes(y=pred1h), colour="blue") + geom_line(aes(y=home_wp), colour="red") +
        scale_x_reverse() + ylim(c(0,1)) + theme_minimal() + xlab("Game Time Remaining (sec)") + ylab("Win %")# + theme(legend.position = "right") can't figure out the legend

View(arrange(filter(train, game_id == "2023_15_PHI_SEA"), -game_seconds_remaining))

#difference
ggplot(filter(train, game_id == "2023_15_PHI_SEA"), aes(x=game_seconds_remaining)) + geom_line(aes(y=100*(pred1h-home_wp)), size = 2, colour="orange") +# geom_line(aes(y=home_wp), colour="red") +
  scale_x_reverse() + ylim(c(-50,50)) + theme_minimal() + xlab("Game Time Remaining (seconds)") + ylab("Difference HWP vs Model HWP")


#average
avg_train <- train %>%
  filter(!is.na(home_wp), !is.na(pred1h)) %>%
  group_by(game_seconds_remaining) %>%
  summarize(average_wp_diff = mean(pred1h-home_wp))

#going to percentages
ggplot(avg_train, aes(x=game_seconds_remaining)) + geom_line(aes(y=100*average_wp_diff), size = 1, colour="orange") +
  scale_x_reverse() + ylim(c(-10,10)) + theme_minimal() + xlab("Game Time Remaining (seconds)") + ylab("Avg_HWP_diff")


View(data %>%
  filter(game_id == '2023_15_PHI_SEA') %>%
  select(home_team, total_home_score, home_score, away_team, total_away_score, away_score, score_differential, posteam, qtr, time, game_seconds_remaining, home_wp, desc) %>%
  arrange(-game_seconds_remaining)
)

colnames(data)
#could organize by down, etc. graph for each, averages off, see which are causing worst errors


View(final_table[final_table$game_id == '2023_15_PHI_SEA',])


#sandbox
View(arrange(head(train %>%
       filter(!is.na(home_wp)), n = 50000), game_seconds_remaining))

View(arrange(distinct(filter(train, game_id == '2023_12_BUF_PHI')), -game_seconds_remaining))

View(filter(train, game_id == "2023_12_BUF_PHI"))


