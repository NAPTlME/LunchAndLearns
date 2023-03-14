libraries = c("stringr", "dplyr", "rjson", "httr")

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


#### Queries ####

# remove all vertices
#gremlinQuery("g.V().drop().iterate()", jgUrl)

gremlinQuery("1+1", jgUrl)

gremlinQuery("g.V().count()", jgUrl, T) %>% str

gremlinQuery("g.E().count()", jgUrl, T) %>% str

# label counts
gremlinQuery("g.V().group().by(label).by(count())", jgUrl, T) %>% str

# edge label counts
gremlinQuery("g.E().group().by(label).by(count())", jgUrl, T) %>% str

# count of skills by category
gremlinQuery("g.V().hasLabel('category').group().by().by(bothE().count())", jgUrl, T) %>% str

gremlinQuery("g.V().hasLabel('category').group().by().by(inE().count())", jgUrl, T) %>% str

gremlinQuery("g.V().hasLabel('category').group().by().by(outE().count())", jgUrl, T) %>% str

gremlinQuery("g.V().hasLabel('practitioner').group().by().by('firstName').by(outE().hasLabel('hasSkill').count())", jgUrl, T) %>% str

#tmp2 = gremlinQuery("g.V().limit(1)", jgUrl, T)

gremlinQuery("g.V().hasLabel('practitioner').limit(1)", jgUrl, T) %>% str

gremlinQuery("g.V().hasLabel('practice').group().by('name').by(__.in('partOf').group().by().by(out('hasSkill').out('partOf').group().by('name').by(count())).select(values).unfold().unfold().group().by(keys).by(select(values).mean())).unfold()", jgUrl, T) %>% str
