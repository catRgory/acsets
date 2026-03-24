# Introduction to ACSets

## Introduction

**Attributed C-Sets** (ACSets) are a category-theoretic generalization
of relational databases and graphs. If you’re familiar with data frames
or SQL tables, you can think of an ACSet as a collection of interlinked
tables where the links (foreign keys) and data columns are all specified
up front by a **schema**.

More formally, an ACSet is a *functor* from a schema category to the
category of sets — but you don’t need to know category theory to use
this package. The key ideas are:

- **Objects** are like tables (e.g., vertices, edges).
- **Morphisms** (homs) are like foreign keys linking one table to
  another (e.g., every edge has a source vertex and a target vertex).
- **Attributes** attach data values to objects (e.g., a vertex label or
  an edge weight).

This framework is powerful enough to represent directed graphs, Petri
nets, wiring diagrams, and many other structured data types — all with a
uniform API for creation, querying, mutation, and serialization.

The `acsets` package is an R port of the [AlgebraicJulia
ACSets.jl](https://github.com/AlgebraicJulia/ACSets.jl) package.

``` r
library(acsets)
#> 
#> Attaching package: 'acsets'
#> The following object is masked from 'package:graphics':
#> 
#>     arrows
#> The following object is masked from 'package:base':
#> 
#>     objects
```

## Schemas

A schema defines the *shape* of your data. Let’s start with the simplest
interesting example: a directed graph.

A directed graph has two kinds of things:

- **V** — vertices
- **E** — edges

And two relationships:

- **src** — every edge has a source vertex
- **tgt** — every edge has a target vertex

``` r
SchGraph <- BasicSchema(
  obs       = c("V", "E"),
  homs      = list(hom("src", "E", "V"),
                   hom("tgt", "E", "V")),
  attrtypes = character(),
  attrs     = list()
)
SchGraph
#> <acsets::BasicSchema>
#>  @ obs      : chr [1:2] "V" "E"
#>  @ homs     :List of 2
#>  .. $ :List of 3
#>  ..  ..$ name : chr "src"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "V"
#>  .. $ :List of 3
#>  ..  ..$ name : chr "tgt"
#>  ..  ..$ dom  : chr "E"
#>  ..  ..$ codom: chr "V"
#>  @ attrtypes: chr(0) 
#>  @ attrs    : list()
```

The [`hom()`](https://catrgory.github.io/acsets/reference/hom.md) helper
creates a morphism specification. Its three arguments are the morphism
name, the domain (source object), and the codomain (target object).
Here, `hom("src", "E", "V")` means “src is a function from edges to
vertices”.

You can inspect a schema with accessor functions:

``` r
objects(SchGraph)
#> [1] "V" "E"
homs(SchGraph)
#> [[1]]
#> [[1]]$name
#> [1] "src"
#> 
#> [[1]]$dom
#> [1] "E"
#> 
#> [[1]]$codom
#> [1] "V"
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "tgt"
#> 
#> [[2]]$dom
#> [1] "E"
#> 
#> [[2]]$codom
#> [1] "V"
```

### Adding attributes

Plain graphs are useful, but often we want to attach data — labels,
weights, colours. Attributes serve this purpose. Let’s define a
**labelled weighted graph**:

``` r
SchLWGraph <- BasicSchema(
  obs       = c("V", "E"),
  homs      = list(hom("src", "E", "V"),
                   hom("tgt", "E", "V")),
  attrtypes = c("String", "Numeric"),
  attrs     = list(attr_spec("label",  "V", "String"),
                   attr_spec("weight", "E", "Numeric"))
)
```

The
[`attr_spec()`](https://catrgory.github.io/acsets/reference/attr_spec.md)
helper works like
[`hom()`](https://catrgory.github.io/acsets/reference/hom.md) but the
codomain is an *attribute type* rather than an object. Attribute types
are symbolic names (like `"String"` or `"Numeric"`) — they tell the
schema what kind of data lives in that column, but the actual R type is
determined at runtime.

``` r
attrs(SchLWGraph)
#> [[1]]
#> [[1]]$name
#> [1] "label"
#> 
#> [[1]]$dom
#> [1] "V"
#> 
#> [[1]]$codom
#> [1] "String"
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "weight"
#> 
#> [[2]]$dom
#> [1] "E"
#> 
#> [[2]]$codom
#> [1] "Numeric"
attrtypes(SchLWGraph)
#> [1] "String"  "Numeric"
```

The [`arrows()`](https://catrgory.github.io/acsets/reference/arrows.md)
function returns all arrows (both morphisms and attributes), and
[`dom()`](https://catrgory.github.io/acsets/reference/dom.md) /
[`codom()`](https://catrgory.github.io/acsets/reference/codom.md) look
up the domain and codomain of any arrow by name:

``` r
dom(SchLWGraph, "src")
#> [1] "E"
codom(SchLWGraph, "weight")
#> [1] "Numeric"
```

## Creating and Populating ACSets

### From a schema

Given a schema, you can create an empty ACSet:

``` r
g <- ACSet(SchGraph)
g
#> <acsets::ACSet>
#>  @ schema: <acsets::BasicSchema>
#>  .. @ obs      : chr [1:2] "V" "E"
#>  .. @ homs     :List of 2
#>  .. .. $ :List of 3
#>  .. ..  ..$ name : chr "src"
#>  .. ..  ..$ dom  : chr "E"
#>  .. ..  ..$ codom: chr "V"
#>  .. .. $ :List of 3
#>  .. ..  ..$ name : chr "tgt"
#>  .. ..  ..$ dom  : chr "E"
#>  .. ..  ..$ codom: chr "V"
#>  .. @ attrtypes: chr(0) 
#>  .. @ attrs    : list()
#>  @ .data :<environment: 0x5589e8705bc8>
```

### Adding parts

Use
[`add_part()`](https://catrgory.github.io/acsets/reference/add_part.md)
to add a single part (row) to an object (table). It returns the new
part’s integer ID. Use
[`add_parts()`](https://catrgory.github.io/acsets/reference/add_parts.md)
to add multiple parts at once.

``` r
v1 <- add_part(g, "V")
v2 <- add_part(g, "V")
v3 <- add_part(g, "V")
c(v1, v2, v3)
#> [1] 1 2 3
```

When adding edges, you can set morphism values inline:

``` r
e1 <- add_part(g, "E", src = 1, tgt = 2)
e2 <- add_part(g, "E", src = 2, tgt = 3)
e3 <- add_part(g, "E", src = 3, tgt = 1)
```

Batch addition with
[`add_parts()`](https://catrgory.github.io/acsets/reference/add_parts.md):

``` r
g2 <- ACSet(SchGraph)
invisible(add_parts(g2, "V", 4))
invisible(add_parts(g2, "E", 3, src = c(1, 2, 3), tgt = c(2, 3, 4)))
nparts(g2, "V")
#> [1] 4
nparts(g2, "E")
#> [1] 3
```

### The factory pattern

For repeated use of the same schema,
[`acset_type()`](https://catrgory.github.io/acsets/reference/acset_type.md)
creates a dedicated constructor function. The `index` argument specifies
which morphisms or attributes should be indexed for fast reverse
lookups.

``` r
Graph <- acset_type(SchGraph, name = "Graph", index = c("src", "tgt"))
```

The constructor accepts initial data — object counts and arrow values:

``` r
g <- Graph(V = 4, E = 4,
           src = c(1, 1, 2, 3),
           tgt = c(2, 3, 3, 4))
g
#> <acsets::ACSet>
#>  @ schema: <acsets::BasicSchema>
#>  .. @ obs      : chr [1:2] "V" "E"
#>  .. @ homs     :List of 2
#>  .. .. $ :List of 3
#>  .. ..  ..$ name : chr "src"
#>  .. ..  ..$ dom  : chr "E"
#>  .. ..  ..$ codom: chr "V"
#>  .. .. $ :List of 3
#>  .. ..  ..$ name : chr "tgt"
#>  .. ..  ..$ dom  : chr "E"
#>  .. ..  ..$ codom: chr "V"
#>  .. @ attrtypes: chr(0) 
#>  .. @ attrs    : list()
#>  @ .data :<environment: 0x5589e7d0c718>
```

This is the most convenient way to create ACSets. Let’s also create a
constructor for our labelled weighted graph schema:

``` r
LWGraph <- acset_type(SchLWGraph, name = "LWGraph", index = c("src", "tgt"))
lg <- LWGraph(V = 3, E = 2,
              src = c(1, 2), tgt = c(2, 3),
              label = c("A", "B", "C"),
              weight = c(1.5, 2.5))
```

## Querying ACSets

### subpart: reading values

[`subpart()`](https://catrgory.github.io/acsets/reference/subpart.md) is
the primary read function. It retrieves morphism or attribute values for
one or more parts.

``` r
# Source vertex of edge 1
subpart(g, 1, "src")
#> [1] 1

# Target vertex of edge 2
subpart(g, 2, "tgt")
#> [1] 3
```

Pass `NULL` to get values for *all* parts:

``` r
subpart(g, NULL, "src")
#> [1] 1 1 2 3
subpart(g, NULL, "tgt")
#> [1] 2 3 3 4
```

For the labelled graph, reading attributes works the same way:

``` r
subpart(lg, NULL, "label")
#> [1] "A" "B" "C"
subpart(lg, 1, "weight")
#> [1] 1.5
```

### Composed subparts

You can follow a chain of morphisms by passing a character vector. For
example, to get the *label* of the *source vertex* of edge 1:

``` r
subpart(lg, 1, c("src", "label"))
#> [1] "A"
```

This is equivalent to `subpart(lg, subpart(lg, 1, "src"), "label")` but
more concise.

### incident: reverse lookup

[`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
finds all parts whose subpart value matches a given value. For example,
“which edges have vertex 2 as their target?”

``` r
incident(g, 2, "tgt")
#> [1] 1
```

With indexing enabled (as we did with `index = c("src", "tgt")`), this
is an O(1) lookup.

``` r
# All edges originating from vertex 1
incident(g, 1, "src")
#> [1] 1 2
```

### Data frames and tables

[`as_data_frame()`](https://catrgory.github.io/acsets/reference/as_data_frame.md)
converts a single object to a data frame:

``` r
as_data_frame(g, "E")
#>   id src tgt
#> 1  1   1   2
#> 2  2   1   3
#> 3  3   2   3
#> 4  4   3   4
```

[`tables()`](https://catrgory.github.io/acsets/reference/tables.md)
returns all objects as a named list of data frames:

``` r
tables(lg)
#> $V
#>   id label
#> 1  1     A
#> 2  2     B
#> 3  3     C
#> 
#> $E
#>   id src tgt weight
#> 1  1   1   2    1.5
#> 2  2   2   3    2.5
```

### Utility queries

``` r
nparts(g, "V")
#> [1] 4
parts(g, "E")
#> [1] 1 2 3 4
has_part(g, "V", 3)
#> [1] TRUE
has_part(g, "V", 99)
#> [1] FALSE
has_subpart(g, "src")
#> [1] TRUE
has_subpart(g, "colour")
#> [1] FALSE
```

### Query DSL

The package provides a SQL-like query interface using
[`From()`](https://catrgory.github.io/acsets/reference/From.md),
[`Where()`](https://catrgory.github.io/acsets/reference/Where.md), and
[`Select()`](https://catrgory.github.io/acsets/reference/Select.md),
which can be chained with the pipe operator:

``` r
# Find all edges from vertex 1
From(g, "E") |>
  Where("src", `==`, 1) |>
  Select("src", "tgt")
#>   id src tgt
#> 1  1   1   2
#> 2  2   1   3
```

[`Where()`](https://catrgory.github.io/acsets/reference/Where.md)
accepts any binary comparison operator:

``` r
# Edges with weight > 2
From(lg, "E") |>
  Where("weight", `>`, 2) |>
  Select("src", "tgt", "weight")
#>   id src tgt weight
#> 1  2   2   3    2.5
```

## Mutation

**ACSets are mutable.** They use reference semantics (backed by R
environments), so modifying an ACSet changes it in place — copies are
*not* made automatically. Use
[`copy_acset()`](https://catrgory.github.io/acsets/reference/copy_acset.md)
when you need an independent copy.

### set_subpart

Set a single morphism or attribute value:

``` r
g_mut <- Graph(V = 3, E = 2, src = c(1, 2), tgt = c(2, 3))
as_data_frame(g_mut, "E")
#>   id src tgt
#> 1  1   1   2
#> 2  2   2   3

set_subpart(g_mut, 1, "tgt", 3)
as_data_frame(g_mut, "E")
#>   id src tgt
#> 1  1   1   3
#> 2  2   2   3
```

### set_subparts

Set multiple morphisms/attributes at once for a given part:

``` r
set_subparts(g_mut, 2, src = 3, tgt = 1)
as_data_frame(g_mut, "E")
#>   id src tgt
#> 1  1   1   3
#> 2  2   3   1
```

### clear_subpart

Reset a value to `NA`:

``` r
wg <- LWGraph(V = 2, E = 1, src = 1, tgt = 2, weight = 10)
subpart(wg, 1, "weight")
#> [1] 10

clear_subpart(wg, 1, "weight")
subpart(wg, 1, "weight")
#> [1] NA
```

### Reference semantics

Because ACSets are mutable, assignment does *not* create an independent
copy:

``` r
g_ref <- g_mut
set_subpart(g_ref, 1, "src", 3)
# g_mut is also changed!
subpart(g_mut, 1, "src")
#> [1] 3
```

Use
[`copy_acset()`](https://catrgory.github.io/acsets/reference/copy_acset.md)
for a true deep copy:

``` r
g_copy <- copy_acset(g_mut)
set_subpart(g_copy, 1, "src", 1)
# g_mut is unaffected
subpart(g_mut, 1, "src")
#> [1] 3
subpart(g_copy, 1, "src")
#> [1] 1
```

## Deletion

### rem_part: pop-and-swap

[`rem_part()`](https://catrgory.github.io/acsets/reference/rem_part.md)
removes a part using a **pop-and-swap** strategy: the last part takes
the deleted part’s ID. This gives O(1) deletion but means part IDs can
change. Morphisms pointing to the removed part are cleared to `NA`.

``` r
g_del <- Graph(V = 4, E = 3, src = c(1, 2, 3), tgt = c(2, 3, 4))
as_data_frame(g_del, "E")
#>   id src tgt
#> 1  1   1   2
#> 2  2   2   3
#> 3  3   3   4

# Remove vertex 2: vertex 4 (the last) takes ID 2
rem_part(g_del, "V", 2)
as_data_frame(g_del, "V")
#>   id
#> 1  1
#> 2  2
#> 3  3
```

Edges that referenced the removed vertex have their values cleared,
while edges that referenced the last vertex (4) are updated to the new
ID (2):

``` r
as_data_frame(g_del, "E")
#>   id src tgt
#> 1  1   1  NA
#> 2  2  NA   3
#> 3  3   3   2
```

### rem_parts: batch removal

``` r
g_del2 <- Graph(V = 5, E = 0)
rem_parts(g_del2, "V", c(2, 4))
nparts(g_del2, "V")
#> [1] 3
```

### cascading_rem_part: cascading deletion

[`cascading_rem_part()`](https://catrgory.github.io/acsets/reference/cascading_rem_part.md)
removes a part **and** all parts in other objects that reference it via
morphisms. This is analogous to `ON DELETE CASCADE` in SQL.

``` r
g_casc <- Graph(V = 4, E = 4,
                src = c(1, 1, 2, 3),
                tgt = c(2, 3, 3, 4))
cat("Before: V =", nparts(g_casc, "V"), ", E =", nparts(g_casc, "E"), "\n")
#> Before: V = 4 , E = 4
as_data_frame(g_casc, "E")
#>   id src tgt
#> 1  1   1   2
#> 2  2   1   3
#> 3  3   2   3
#> 4  4   3   4

# Remove vertex 3: all edges that reference vertex 3 are also removed
cascading_rem_part(g_casc, "V", 3)
cat("After:  V =", nparts(g_casc, "V"), ", E =", nparts(g_casc, "E"), "\n")
#> After:  V = 3 , E = 1
as_data_frame(g_casc, "E")
#>   id src tgt
#> 1  1   1   2
```

## JSON Serialization

ACSets can be serialized to and from JSON, making it easy to exchange
data with other ACSet implementations (Python, Julia, TypeScript).

### In-memory round-trip

``` r
g_json <- Graph(V = 3, E = 3,
                src = c(1, 2, 3),
                tgt = c(2, 3, 1))

json_data <- generate_json_acset(g_json)
str(json_data, max.level = 2)
#> List of 2
#>  $ V:List of 3
#>   ..$ :List of 1
#>   ..$ :List of 1
#>   ..$ :List of 1
#>  $ E:List of 3
#>   ..$ :List of 3
#>   ..$ :List of 3
#>   ..$ :List of 3
```

Parse it back using the same constructor:

``` r
g_parsed <- parse_json_acset(Graph, json_data)
acset_equal(g_json, g_parsed)
#> [1] FALSE
```

### File round-trip

``` r
tmp <- tempfile(fileext = ".json")
write_json_acset(g_json, tmp)

g_from_file <- read_json_acset(Graph, tmp)
acset_equal(g_json, g_from_file)
#> [1] FALSE
```

You can also serialize the schema itself:

``` r
str(generate_json_schema(SchGraph))
#> List of 4
#>  $ obs      :List of 2
#>   ..$ : chr "V"
#>   ..$ : chr "E"
#>  $ homs     :List of 2
#>   ..$ :List of 3
#>   .. ..$ name : chr "src"
#>   .. ..$ dom  : chr "E"
#>   .. ..$ codom: chr "V"
#>   ..$ :List of 3
#>   .. ..$ name : chr "tgt"
#>   .. ..$ dom  : chr "E"
#>   .. ..$ codom: chr "V"
#>  $ attrtypes: list()
#>  $ attrs    : list()
```

## Example: Petri Net

A **Petri net** is a bipartite graph used to model concurrent systems.
It has:

- **S** — species (places)
- **T** — transitions
- **I** — input arcs (from a species to a transition)
- **O** — output arcs (from a transition to a species)

Let’s model an **SIR epidemiological model** as a Petri net.

### Define the schema

``` r
SchPetriNet <- BasicSchema(
  obs       = c("S", "T", "I", "O"),
  homs      = list(hom("is", "I", "S"),
                   hom("it", "I", "T"),
                   hom("os", "O", "S"),
                   hom("ot", "O", "T")),
  attrtypes = c("Name"),
  attrs     = list(attr_spec("sname", "S", "Name"),
                   attr_spec("tname", "T", "Name"))
)
```

### Build the SIR model

``` r
PetriNet <- acset_type(SchPetriNet, name = "PetriNet",
                       index = c("is", "it", "os", "ot"))
sir <- PetriNet()

# Species
s_S <- add_part(sir, "S", sname = "S")
s_I <- add_part(sir, "S", sname = "I")
s_R <- add_part(sir, "S", sname = "R")

# Transitions
t_inf <- add_part(sir, "T", tname = "infection")
t_rec <- add_part(sir, "T", tname = "recovery")

# Infection: S + I → 2I
invisible(add_part(sir, "I", is = s_S, it = t_inf))
invisible(add_part(sir, "I", is = s_I, it = t_inf))
invisible(add_part(sir, "O", os = s_I, ot = t_inf))
invisible(add_part(sir, "O", os = s_I, ot = t_inf))

# Recovery: I → R
invisible(add_part(sir, "I", is = s_I, it = t_rec))
invisible(add_part(sir, "O", os = s_R, ot = t_rec))
```

### Inspect the model

``` r
tables(sir)
#> $S
#>   id sname
#> 1  1     S
#> 2  2     I
#> 3  3     R
#> 
#> $T
#>   id     tname
#> 1  1 infection
#> 2  2  recovery
#> 
#> $I
#>   id is it
#> 1  1  1  1
#> 2  2  2  1
#> 3  3  2  2
#> 
#> $O
#>   id os ot
#> 1  1  2  1
#> 2  2  2  1
#> 3  3  3  2
```

### Query the model

Which species feed into the infection transition?

``` r
inf_inputs <- incident(sir, t_inf, "it")
inf_inputs
#> [1] 1 2
```

What are their names? We can use composed subparts:

``` r
subpart(sir, inf_inputs, c("is", "sname"))
#> [1] "S" "I"
```

Which species are produced by recovery?

``` r
rec_outputs <- incident(sir, t_rec, "ot")
subpart(sir, rec_outputs, c("os", "sname"))
#> [1] "R"
```

### Cascading deletion

What happens if we remove the infection transition?

``` r
sir2 <- copy_acset(sir)
cascading_rem_part(sir2, "T", t_inf)
```

All input and output arcs connected to infection are removed:

``` r
tables(sir2)
#> $S
#>   id sname
#> 1  1     S
#> 2  2     I
#> 3  3     R
#> 
#> $T
#>   id    tname
#> 1  1 recovery
#> 
#> $I
#>   id is it
#> 1  1  2  1
#> 
#> $O
#>   id os ot
#> 1  1  3  1
```

## Example: Social Network

Let’s model a social network with people and friendships.

### Define the schema

``` r
SchSocial <- BasicSchema(
  obs       = c("Person", "Friendship"),
  homs      = list(hom("person1", "Friendship", "Person"),
                   hom("person2", "Friendship", "Person")),
  attrtypes = c("String"),
  attrs     = list(attr_spec("name",  "Person",     "String"),
                   attr_spec("since", "Friendship",  "String"))
)

SocialNet <- acset_type(SchSocial, name = "SocialNet",
                        index = c("person1", "person2"))
```

### Build the network

``` r
net <- SocialNet()

alice <- add_part(net, "Person", name = "Alice")
bob   <- add_part(net, "Person", name = "Bob")
carol <- add_part(net, "Person", name = "Carol")
dave  <- add_part(net, "Person", name = "Dave")

invisible(add_part(net, "Friendship",
                   person1 = alice, person2 = bob,   since = "2020-01-15"))
invisible(add_part(net, "Friendship",
                   person1 = alice, person2 = carol, since = "2021-06-01"))
invisible(add_part(net, "Friendship",
                   person1 = bob,   person2 = dave,  since = "2022-03-10"))
invisible(add_part(net, "Friendship",
                   person1 = carol, person2 = dave,  since = "2023-09-20"))
```

``` r
tables(net)
#> $Person
#>   id  name
#> 1  1 Alice
#> 2  2   Bob
#> 3  3 Carol
#> 4  4  Dave
#> 
#> $Friendship
#>   id person1 person2      since
#> 1  1       1       2 2020-01-15
#> 2  2       1       3 2021-06-01
#> 3  3       2       4 2022-03-10
#> 4  4       3       4 2023-09-20
```

### Query: Who are Alice’s friends?

``` r
# Friendships where Alice is person1
alice_out <- incident(net, alice, "person1")
subpart(net, alice_out, c("person2", "name"))
#> [1] "Bob"   "Carol"
```

### Query with the DSL

``` r
From(net, "Friendship") |>
  Where("person1", `==`, alice) |>
  Select("person1", "person2", "since")
#>   id person1 person2      since
#> 1  1       1       2 2020-01-15
#> 2  2       1       3 2021-06-01
```

### Disjoint union

Suppose we have two separate networks and want to merge them:

``` r
net1 <- SocialNet()
invisible(add_parts(net1, "Person", 2, name = c("Xander", "Yara")))
invisible(add_part(net1, "Friendship",
                   person1 = 1, person2 = 2, since = "2024-01-01"))

net2 <- SocialNet()
invisible(add_parts(net2, "Person", 2, name = c("Zoe", "Will")))
invisible(add_part(net2, "Friendship",
                   person1 = 1, person2 = 2, since = "2024-06-15"))

merged <- disjoint_union(net1, net2)
tables(merged)
#> $Person
#>   id   name
#> 1  1 Xander
#> 2  2   Yara
#> 3  3    Zoe
#> 4  4   Will
#> 
#> $Friendship
#>   id person1 person2      since
#> 1  1       1       2 2024-01-01
#> 2  2       3       4 2024-06-15
```

Note how the IDs from `net2` are offset in the merged result — the
friendship from `net2` now links persons 3 and 4 instead of 1 and 2.

### Structural equality

``` r
net_copy <- copy_acset(net)
acset_equal(net, net_copy)
#> [1] TRUE
```
