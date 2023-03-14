#!/usr/bin/env python3
"""
Talking to JanusGraph from Python.
http://tinkerpop.apache.org/docs/current/reference/#gremlin-python
"""

# need to pip install aiogremlin and gremlinpython

from gremlin_python.structure.graph import Graph
from gremlin_python.driver.driver_remote_connection import DriverRemoteConnection
from gremlin_python.process.graph_traversal import *
from gremlin_python.process.traversal import Column
#from gremlin_python.driver.


TRAVERSAL_SOURCE = 'g'

graph = Graph()
connection = DriverRemoteConnection('ws://localhost:8182/gremlin', TRAVERSAL_SOURCE)
g = graph.traversal().withRemote(connection)

path = g.V().count().next()







# semi complex traversal from the end of the presentation:
g.V().hasLabel('practice').group().by('name').by(in_('partOf').group().by().by(out('hasSkill').out('partOf').group().by('name').by(count())).select(Column.values).unfold().unfold().group().by(Column.keys).by(select(Column.values).mean())).unfold().toList()

"""
Example single value return
g.V().count().next()

Example iterator (cast to list)
path = g.V().has('code', 'HNL')\
            .repeat(out().simplePath())\
            .until(has('code', 'HOU'))\
            .path()\
            .by(valueMap('code', 'city'))\
            .limit(1)\
            .toList()

for i, vertex in enumerate(path[0]):
    code = vertex["code"][0]
    city = vertex["city"][0]
    print(f'Hop {i+1}: {code} - {city}')
"""