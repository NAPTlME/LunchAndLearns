library(stringr)
library(dplyr)
library(tidyr)
library(readxl)
library(ggplot2)

#### Import ####
f = file.choose()

df = read_excel(f, col_names = F, skip = 3)

dfColnames = as.character(df[2,])

df = df[!is.na(dfColnames) & dfColnames != "NA"]

colnames(df) = df[2,]

colnames(df)[1:2] = str_replace_all(colnames(df)[1:2], "[\\s\\-]+", "_")

#### Practice (Skill) ####

skillPractices = as.character(df[1,])
skillPracticeIndices = which(!is.na(skillPractices))

for (i in 1:length(skillPracticeIndices)){
  sp = skillPractices[skillPracticeIndices[i]]
  endIndex = ifelse(i == length(skillPracticeIndices), length(skillPractices), skillPracticeIndices[i+1]-1)
  df[1,skillPracticeIndices[i]:endIndex] = sp
}

#### Practice (Practitioner) ####

df$Practice = ""

practiceIndices = which(is.na(df$First_Name))
practices = df$Last_Name[practiceIndices]

for (i in 1:length(practiceIndices)){
  p = practices[i]
  endIndex = ifelse(i == length(practiceIndices), nrow(df), practiceIndices[i+1]-1)
  df$Practice[practiceIndices[i]:endIndex] = p
}

#### tidy ####

colnames(df)[3:(ncol(df)-1)] = paste(df[1,3:(ncol(df)-1)], colnames(df)[3:(ncol(df)-1)], sep = "|")
# remove colname rows
df = df[3:nrow(df),]
# remove practice rows
df = df[!is.na(df$First_Name),]

df = df %>%
  gather("Key", "Value", -Last_Name, -First_Name, -Practice) %>%
  mutate(Skill_Practice = str_match(Key, "^[^\\|]+"),
         Skill = str_match(Key, "[^\\|]+$"),
         Value = as.numeric(Value),
         Value = ifelse(is.na(Value), 0, Value),
         Knows = Value >= 1,
         IsExpert = Value > 1) %>% 
  select(-Key, -Value)

# Keep only Known rows
filteredDf = df %>%
  filter(Knows) %>%
  select(-Knows)

write.csv(filteredDf, file.choose(), row.names = F)