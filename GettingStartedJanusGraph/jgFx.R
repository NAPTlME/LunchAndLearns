libraries = c("rjson", "httr")

for (x in libraries) {
  if (!require(x, character.only = T)) {
    install.packages(x)
    library(x, character.only = T)
  }
}

#### Fx ####

basicQuery = function(payload, uri) {
  response = POST(uri,
                    content_type_json(),
                    body = payload)
  if (response$status_code != 200){
    stop(paste0("Query failed: ", payload, "\nWith status code: ", response$status_code,
                "\n",content(response)))
  }
  content(response)
}

gremlinQuery = function(queryString, uri, prettify = F) {
  result = basicQuery(toJSON(list(gremlin=queryString)), uri)
  if (prettify) {
    prettyResult(result)
  } else {
    result
  }
}

addVertex = function(label, properties, traversalSource, uri) {
  # adding label as an additional property to allow for indexing
  properties$type = label
  # add in extra quotes for strings (should really do this for any type that is not recognized by jg, no time now)
  for (i in 1:length(properties)) {
    x = properties[[i]]
    if (is.character(x)) {
      x = paste0("'", x, "'")
    }
    properties[[i]] = x
  }
  # for now assume there will always be properties
  queryString = paste0(traversalSource, ".addV(", properties$type, ").",
                       paste0("property('", names(properties), "',", unlist(properties), ")", collapse = "."))
  # should call next?
  gremlinQuery(queryString, uri)
}

addEdge = function(label, fromI, toI, properties, traversalSource, uri) {
  # adding label as an additional property to allow for indexing
  properties$type = label
  # add in extra quotes for strings (should really do this for any type that is not recognized by jg, no time now)
  for (i in 1:length(properties)) {
    x = properties[[i]]
    if (is.character(x)) {
      x = paste0("'", x, "'")
    }
    properties[[i]] = x
  }
  
  queryString = paste0(traversalSource, ".V(", fromI, ").addE(", properties$type, ").to(V(", toI, ")).",
                       paste0("property('", names(properties), "',", unlist(properties), ")", collapse = "."),
                       ".iterate()")
  gremlinQuery(queryString, uri)
}

getVertexId = function(x){
  # quickly made function to get the vertex id from a query result with a single vertex
  x$result$data$`@value`[[1]]$`@value`$id$`@value`
}

prettyResult = function(x) {
  prettyData(x$result$data)
}

prettyData = function(x) {
  if (class(x) != "list") {
    x
  } else {
    type = x$`@type`
    if (is.null(type)) {
      lapply(x, prettyData)
    } else {
      switch(
        type,
        "g:List" = {
          lapply(x$`@value`, prettyData)
        },
        "g:Map" = {
          if (class(x$`@value`[[1]]) != "list") {
            keys = sapply(seq(1, length(x$`@value`), by = 2), function(i) x$`@value`[[i]])
            setNames(lapply(seq(2,length(x$`@value`), by = 2), function(i) prettyData(x$`@value`[[i]])), keys)
          } else {
            lapply(seq(1, length(x$`@value`), by = 2), function(i) prettyData(x$`@value`[i:(i+1)]))
          }
        },
        "g:Vertex" = {
          prettyData(x$`@value`)
        },
        "g:VertexProperty" = {
          prettyData(x$`@value`)
        },
        {
          #print(type)
          x$`@value`
        }
      )
    }
  }
}





















