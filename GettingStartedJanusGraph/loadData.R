libraries = c("stringr", "dplyr", "tidyr")

for (x in libraries) {
  if (!require(x, character.only = T)) {
    install.packages(x)
    library(x, character.only = T)
  }
}

setwd("~/GitHub/LunchAndLearns/GettingStartedJanusGraph/")

source("jgFx.R")

#### Setup JG variables ####
graphName = "graph"
graphTraversal = "g"
jgUrl = "http://localhost:8182"

#### Fx ####



#### read data ####
filepath = file.choose()
df = read.csv(filepath)

#### prep data ####

df = df %>%
  mutate(Skill = str_replace_all(Skill, "\\s+", " "))

# provide identifiers for each data type

practitionerDf = df %>% select(Last_Name, First_Name) %>% 
  distinct() %>%
  mutate(practitionerIndex = 0)

practiceDf = df %>% select(Practice) %>%
  distinct() %>%
  mutate(practiceIndex = 0)

skillCategoryDf = df %>% select(Skill_Practice) %>%
  distinct() %>%
  mutate(skillCategoryIndex = 0)

skillDf = df %>% select(Skill) %>%
  distinct() %>%
  mutate(skillIndex = 0)

# create all vertices
print("Creating all Vertices")
for (i in 1:nrow(practitionerDf)) {
  p = list(lastName = practitionerDf$Last_Name[i],
           firstName = practitionerDf$First_Name[i])
  v = addVertex("practitioner", p, graphTraversal, jgUrl)
  practitionerDf$practitionerIndex[i] = getVertexId(v)
}

for (i in 1:nrow(practiceDf)) {
  p = list(name = practiceDf$Practice[i])
  v = addVertex("practice", p, graphTraversal, jgUrl)
  practiceDf$practiceIndex[i] = getVertexId(v)
}

for (i in 1:nrow(skillCategoryDf)) {
  p = list(name = skillCategoryDf$Skill_Practice[i])
  v = addVertex("category", p, graphTraversal, jgUrl)
  skillCategoryDf$skillCategoryIndex[i] = getVertexId(v)
}

for (i in 1:nrow(skillDf)) {
  p = list(name = skillDf$Skill[i])
  v = addVertex("skill", p, graphTraversal, jgUrl)
  skillDf$skillIndex[i] = getVertexId(v)
}


df = df %>%
  left_join(practitionerDf, by = c("Last_Name", "First_Name")) %>%
  left_join(practiceDf, by = "Practice") %>%
  left_join(skillCategoryDf, by = "Skill_Practice") %>%
  left_join(skillDf, by = "Skill")

# edges

practitionerToPracticeDf = df %>%
  select(practitionerIndex, practiceIndex) %>%
  distinct()

practitionerToSkillDf = df %>%
  select(practitionerIndex, skillIndex, IsExpert) %>%
  distinct()

skillToCategoryDf = df %>%
  select(skillIndex, skillCategoryIndex) %>%
  distinct()

for (i in 1:nrow(practitionerToPracticeDf)) {
  fromI = practitionerToPracticeDf$practitionerIndex[i]
  toI = practitionerToPracticeDf$practiceIndex[i]
  p = list()
  addEdge("partOf", fromI, toI, p, graphTraversal, jgUrl)
}

for (i in 1:nrow(practitionerToSkillDf)) {
  fromI = practitionerToSkillDf$practitionerIndex[i]
  toI = practitionerToSkillDf$skillIndex[i]
  isExpert = tolower(practitionerToSkillDf$IsExpert[i])
  p = list(isExpert = isExpert)
  addEdge("hasSkill", fromI, toI, p, graphTraversal, jgUrl)
}

for (i in 1:nrow(skillToCategoryDf)) {
  fromI = skillToCategoryDf$skillIndex[i]
  toI = skillToCategoryDf$skillCategoryIndex[i]
  p = list()
  addEdge("partOf", fromI, toI, p, graphTraversal, jgUrl)
}



















