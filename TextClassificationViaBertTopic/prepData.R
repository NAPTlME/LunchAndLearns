library(dplyr)
library(stringr)
library(jsonlite)
library(lubridate)

setwd("~/GitHub/LunchAndLearns/TextClassificationViaBertTopic")

source("../../R_SlackApi/slackFx.R")

slackToken = "slackToken"

Sys.setenv(slackToken=readLines("../slackToken.txt")[1])

#slackToken = readLines("../slackToken.txt")[1]

#### Functions ####

#### Get User Info ####

userInfoDf = getUsers(Sys.getenv(slackToken))

#### Get Channels ####

channelsDf = getChannels(Sys.getenv(slackToken))

#### Get Support Text ####

oldest = convertDateTimeToTs(as.POSIXct("2019-07-01 00:00:01", tz = "America/Chicago"))

# get channel conversation counts
#numCalls = 0
convCountsDf = do.call(rbind, lapply(1:nrow(channelsDf), function(i){
  print(paste0(i, ": ", channelsDf$name[i]))
  df = getConversations(Sys.getenv(slackToken), channelsDf$id[i], oldest = oldest)
  
  if(!is.null(df)){
    df %>%
      mutate(name = channelsDf$name[i]) %>%
      group_by(name) %>% 
      count()
  }
}))
channelsRaw = getChannels(Sys.getenv(slackToken), returnRaw = T)

convCountsDf = convCountsDf %>% left_join(
  do.call(rbind, lapply(channelsRaw, function(response.content) {
    do.call(rbind, lapply(response.content$channels, function(x){
      data.frame(id = x$id, name = x$name,
                 purpose = x$purpose$value,
                 is_private = x$is_private,
                 num_members = x$num_members,
                 is_member = x$is_member)
    }))
  })), 
  by = "name")


# channel.support = channelsDf$id[channelsDf$name == "general"]
# # add askmeanything, benefits

channelNames = c("support", "askmeanything", "benefits")
channelNames = "general"

supportDf = do.call(rbind, lapply(channelNames, function(channel) {
  Sys.sleep(60)
  channel.Id = channelsDf$id[channelsDf$name == channel]
  getConversations(Sys.getenv(slackToken), channel.Id, oldest = oldest)
}))

# supportDf = getConversations(Sys.getenv(slackToken), channel.support, oldest = oldest)

#### Prep Text ####

rUrl = "https?://[a-zA-Z0-9\\$\\-_\\.\\+\\!\\*'\\(\\),/]+" # not needed, will gather links via <>

rSlackLink = "<[^<>\\s]+>"

rReaction = ":[^:\\s]+:"

# view most recent messages
View(supportDf %>% arrange(-as.numeric(datetime)))

# example of a slack link
supportDf$text[str_detect(supportDf$text, rSlackLink)][1:3]

#example of a reaction
supportDf$text[str_detect(supportDf$text, rReaction)][1:3]

# arrange by time,
# remove links, user tags, and reactions from text
# remove messages that are empty after this step
# remove channel joined notifications
# remove Channel left notifications
# remove bot messages

botUsers = userInfoDf$name[userInfoDf$is_bot | userInfoDf$is_app_user]
str(botUsers)

nrow(supportDf)

supportDf = supportDf %>%
  arrange(datetime) %>%
  mutate(text = trimws(str_replace_all(str_replace_all(text, rSlackLink, ""), rReaction, ""))) %>%
  filter(text != "") %>%
  filter(text != "has joined the channel") %>%
  filter(text != "has left the channel") %>%
  filter(!(user %in% botUsers))

# recheck row count
nrow(supportDf)
  
# transfer to python for bert, tsne and hdbscan
#write.csv(supportDf %>% select(text), "general.csv")
# using unique text values results in dropping ~150 conversations 
#(hoping to reduce the amount of bot messages posted under a valid user)
write.csv(supportDf %>% group_by(text) %>% filter(row_number() == 1) %>% data.frame() %>% select(text),
          "generalDistinct.csv")


# import from python csv for analysis and classification