/-  c=crunch, gs=graph-store, ms=metadata-store, p=post, r=resource
::
=<
  |_  [our=ship now=@da]
  ++  walk-graph-associations
    |=  [=associations:ms content=? from=@da to=@da]
    ^-  wain
    %-  ~(rep by associations)
    |=  [[=md-resource:ms =association:ms] out=wain]
    ^-  wain
    ?>  ?=(%graph app-name.md-resource)
    ?>  ?=(%graph -.config.metadatum.association)
    :: scry the graph
    ::
    =/  graph=(unit graph:gs)  (scry-graph resource.md-resource)
    ?~  graph
      out
    :: prepare channel-info argument
    ::
    =/  channel-info=channel-info:c
      :*
        group.association
        resource.md-resource
        module.config.metadatum.association
      ==
    :: walk the graph
    ::
    (weld out (walk-graph u.graph content channel-info from to))
  ::
  ++  scry-graph
    |=  graph-resource=resource:r
    ^-  (unit graph:gs)
    =/  scry-response=update:gs
      .^  update:gs
        %gx
        (scot %p our)
        %graph-store
        (scot %da now)
        %graph
        (scot %p entity.graph-resource)
        name.graph-resource
        /noun
      ==
    ?.  ?=(%add-graph -.q.scry-response)
      ~
    ?~  graph.q.scry-response
      ~
    [~ graph.q.scry-response]
  ::
  ++  scry-graph-associations
    |=  ~
    ^-  associations:ms
    .^  associations:ms
      %gx
      (scot %p our)
      %metadata-store
      (scot %da now)
      /app-name/graph/noun
    ==
  --
::
|%
::
:: parsing and formatting
::
++  tac  (cury cat 3)
::
++  resource-to-cord
  |=  =resource:r
  ^-  @t
  :(tac (scot %p entity.resource) '/' (scot %tas name.resource))
::
++  paths-to-resources
  |=  paxs=(list path)
  ^-  (set resource:r)
  %-  ~(gas in *(set resource:r))
  (turn paxs path-to-resource)
::
++  path-to-resource
  |=  pax=path
  ^-  resource:r
  =/  entity=@p  (slav %p -.pax)
  =/  name=@tas  -.+.pax
  [entity name]
::
++  escape-characters-in-cord
  |=  =cord
  ^-  @t
  %-  crip
  %-  mesc
  %-  trip
  cord
::
++  contents-to-cord
  |=  contents=(list content:p)
  ^-  @t
  ?~  contents
    ''
  %+  join-cords
    ' '
  (turn contents content-to-cord)
::
++  content-to-cord
  |=  =content:p
  ^-  @t
  ?-  -.content
    %text       (escape-characters-in-cord text.content)
    %mention    (scot %p ship.content)
    %url        url.content
    %code       expression.content    :: TODO: also print output?
    %reference  (reference-content-to-cord reference.content)
  ==
::
++  reference-content-to-cord
  |=  =reference:p
  ^-  @t
  ?-  -.reference
    %group  (resource-to-cord group.reference)
    %graph  :(tac (resource-to-cord group.reference) ': ' (resource-to-cord resource.uid.reference))
  ==
::
++  format-post-to-cord
  |=  [=post:gs =channel-info:c]
  ^-  @t
  %+  join-cords
    ','
  :~
    (scot %da time-sent.post)
    (scot %p author.post)
    (resource-to-cord group.channel-info)
    (resource-to-cord channel.channel-info)
    (scot %tas channel-type.channel-info)
  ==
::
++  join-cords
  |=  [delimiter=@t cords=(list @t)]
  ^-  @t
  %+  roll  cords
  |=  [cord=@t out=@t]
  ^-  @t
  ?:  =('' out)
    :: don't put delimiter before first element
    ::
    cord
  :(tac out delimiter cord)
::
:: walking graphs
::
++  walk-graph
  |=  [=graph:gs content=? =channel-info:c from=@da to=@da]
  ^-  wain
  %-  flop
  %+  roll
    %+  only-nodes-older-than  to
    %+  only-nodes-newer-than  from
    ~(val by graph)
  |=  [=node:gs out=wain]
  ^-  wain
  =?  out  ?=(%graph -.children.node)
    (weld out (walk-graph p.children.node content channel-info from to))
  ?-  -.post.node
    %|
      :: do not output deleted posts
      ::
      out
    %&
      ?~  contents.p.post.node
        :: do not output structural nodes
        ::
        out
      :_  out
      =/  post-no-content=@t  (format-post-to-cord p.post.node channel-info)
      ?-  content
        %|  post-no-content
        %&
          %+  join-cords  ','
            ~[post-no-content (contents-to-cord contents.p.post.node)]
      ==
  ==
::
:: filters
::
++  filter-associations-by-group-resources
  |=  [=associations:ms group-resources=(set resource:r)]
  ^-  associations:ms
  %-  ~(rep by associations)
  |=  [[=md-resource:ms =association:ms] out=associations:ms]
  ^-  associations:ms
  ?.  (~(has in group-resources) group.association)
    out
  (~(put by out) md-resource association)
:: wrappers for intuitive use of `filter-nodes-by-timestamp`:
::  pass `nodes` as given by the `graph-store` scry and no
::  need to worry about comparators
::
++  only-nodes-older-than
  |=  [time=@da nodes=(list node:gs)]
  %-  flop
  (filter-nodes-by-timestamp (flop nodes) lte time)
::
++  only-nodes-newer-than
  |=  [time=@da nodes=(list node:gs)]
  (filter-nodes-by-timestamp nodes gte time)
::
++  filter-nodes-by-timestamp
  |=  [nodes=(list node:gs) comparator=$-([@ @] ?) time=@da]
  =|  out=(list node:gs)
  :: return `out` in same time-order as `nodes`
  ::
  %-  flop
  |-
  ^-  (list node:gs)
  ?~  nodes
    out
  ?-  -.post.i.nodes
    %|
      :: skip deleted posts
      ::
      $(nodes t.nodes)
    %&
      ?.  (comparator time-sent.p.post.i.nodes time)
        :: assume:
        ::  * time is monotonic
        ::  * first `%.n` we hit indicates nodes further on are `%.n`
        ::    (i.e. `nodes` must be ordered st. they start `%.y`,
        ::     e.g. if want all `nodes` older than given time,
        ::     `nodes` must start with oldest and comparator is `lth`)
        ::
        out
      $(nodes t.nodes, out [i.nodes out])
  ==
::
:: io
::
++  note-write-csv-to-clay
  |=  [pax=path file-content=wain]
  ?>  =(%csv (snag (dec (lent pax)) pax))
  [%c [%info %home %& [pax %ins %csv !>(file-content)]~]]
::
--
