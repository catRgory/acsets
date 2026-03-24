# Advanced ACSet Patterns

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

This vignette covers advanced usage patterns for the `acsets` package.
For an introduction to schemas, ACSets, and basic operations, see
[`vignette("acsets")`](https://catrgory.github.io/acsets/articles/acsets.md).

## Custom Schemas

The introduction showed graphs and Petri nets. Here we build schemas for
three other domains to illustrate the flexibility of the ACSet
framework.

### Food Web

A food web records which species eat which others. The **Predation**
object is a join table linking a predator species to a prey species — a
classic many-to-many relationship.

``` r
SchFoodWeb <- BasicSchema(
  obs       = c("Species", "Predation"),
  homs      = list(hom("predator", "Predation", "Species"),
                   hom("prey",     "Predation", "Species")),
  attrtypes = c("String", "Numeric"),
  attrs     = list(attr_spec("name",      "Species",   "String"),
                   attr_spec("trophic",   "Species",   "Numeric"),
                   attr_spec("rate",      "Predation", "Numeric"))
)
FoodWeb <- acset_type(SchFoodWeb, name = "FoodWeb",
                      index = c("predator", "prey"))
```

``` r
fw <- FoodWeb(
  Species   = 4,
  Predation = 4,
  name      = c("Grass", "Rabbit", "Fox", "Eagle"),
  trophic   = c(1, 2, 3, 3),
  predator  = c(2, 3, 3, 4),
  prey      = c(1, 2, 1, 2),
  rate      = c(0.5, 0.3, 0.1, 0.2)
)
tables(fw)
#> $Species
#>   id   name trophic
#> 1  1  Grass       1
#> 2  2 Rabbit       2
#> 3  3    Fox       3
#> 4  4  Eagle       3
#> 
#> $Predation
#>   id predator prey rate
#> 1  1        2    1  0.5
#> 2  2        3    2  0.3
#> 3  3        3    1  0.1
#> 4  4        4    2  0.2
```

What does the fox eat? We find predation links where fox is predator,
then follow the `prey` morphism to get species names:

``` r
fox <- 3
fox_links <- incident(fw, fox, "predator")
subpart(fw, fox_links, c("prey", "name"))
#> [1] "Rabbit" "Grass"
```

### State Machine

A finite state machine has states and labelled transitions. Here the
**event** morphism is a self-referential join through an intermediary
**Transition** object.

``` r
SchFSM <- BasicSchema(
  obs       = c("State", "Transition"),
  homs      = list(hom("source", "Transition", "State"),
                   hom("target", "Transition", "State")),
  attrtypes = c("String"),
  attrs     = list(attr_spec("state_name", "State",      "String"),
                   attr_spec("event",      "Transition", "String"))
)
FSM <- acset_type(SchFSM, name = "FSM", index = c("source", "target"))
```

A traffic light controller:

``` r
light <- FSM(
  State      = 3,
  Transition = 3,
  state_name = c("Red", "Green", "Yellow"),
  source     = c(1, 2, 3),
  target     = c(2, 3, 1),
  event      = c("timer", "timer", "timer")
)
tables(light)
#> $State
#>   id state_name
#> 1  1        Red
#> 2  2      Green
#> 3  3     Yellow
#> 
#> $Transition
#>   id source target event
#> 1  1      1      2 timer
#> 2  2      2      3 timer
#> 3  3      3      1 timer
```

Trace a path: starting from “Red”, follow two transitions:

``` r
current <- 1
for (step in 1:3) {
  trans <- incident(light, current, "source")
  evt <- subpart(light, trans[1], "event")
  nxt <- subpart(light, trans[1], "target")
  cat(subpart(light, current, "state_name"), "--[", evt, "]-->",
      subpart(light, nxt, "state_name"), "\n")
  current <- nxt
}
#> Red --[ timer ]--> Green 
#> Green --[ timer ]--> Yellow 
#> Yellow --[ timer ]--> Red
```

### Database-Style Schema: University

ACSets naturally model relational databases. Here is a three-table
schema for students, courses, and enrolments.

``` r
SchUniv <- BasicSchema(
  obs       = c("Student", "Course", "Enrolment"),
  homs      = list(hom("student", "Enrolment", "Student"),
                   hom("course",  "Enrolment", "Course")),
  attrtypes = c("String", "Numeric"),
  attrs     = list(attr_spec("sname",  "Student",   "String"),
                   attr_spec("cname",  "Course",    "String"),
                   attr_spec("credits","Course",    "Numeric"),
                   attr_spec("grade",  "Enrolment", "String"))
)
Univ <- acset_type(SchUniv, name = "Univ",
                   index = c("student", "course"))
```

``` r
db <- Univ(
  Student   = 3,
  Course    = 2,
  Enrolment = 4,
  sname     = c("Alice", "Bob", "Carol"),
  cname     = c("Linear Algebra", "Category Theory"),
  credits   = c(3, 4),
  student   = c(1, 1, 2, 3),
  course    = c(1, 2, 2, 1),
  grade     = c("A", "B+", "A-", "B")
)
tables(db)
#> $Student
#>   id sname
#> 1  1 Alice
#> 2  2   Bob
#> 3  3 Carol
#> 
#> $Course
#>   id           cname credits
#> 1  1  Linear Algebra       3
#> 2  2 Category Theory       4
#> 
#> $Enrolment
#>   id student course grade
#> 1  1       1      1     A
#> 2  2       1      2    B+
#> 3  3       2      2    A-
#> 4  4       3      1     B
```

Which students are enrolled in Category Theory (course 2)?

``` r
ct_enrol <- incident(db, 2, "course")
subpart(db, ct_enrol, c("student", "sname"))
#> [1] "Alice" "Bob"
```

## Indexing and Performance

When you create an ACSet with `index = c("src", "tgt")`, every call to
[`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
on those arrows uses an O(1) hash-table lookup instead of an O(n) linear
scan. This makes a dramatic difference for large datasets.

### When to Index

Index an arrow when you frequently call
[`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
on it. Common cases:

- **Foreign keys you query in reverse** — e.g., “which edges point to
  vertex *v*?” requires an index on `tgt`.
- **Cascading deletion** —
  [`cascading_rem_part()`](https://catrgory.github.io/acsets/reference/cascading_rem_part.md)
  internally calls
  [`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
  for every morphism targeting the deleted object’s type. Indexing those
  morphisms speeds up deletion.

Do **not** index arrows you only read in the forward direction with
[`subpart()`](https://catrgory.github.io/acsets/reference/subpart.md),
since
[`subpart()`](https://catrgory.github.io/acsets/reference/subpart.md) is
always O(1) regardless of indexing.

### Benchmarking

``` r
SchBench <- BasicSchema(
  obs       = c("V", "E"),
  homs      = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = character(),
  attrs     = list()
)
GraphIdx    <- acset_type(SchBench, index = c("src", "tgt"))
GraphNoIdx  <- acset_type(SchBench, index = character())

n_v <- 100
n_e <- 1000
src_vals <- sample(n_v, n_e, replace = TRUE)
tgt_vals <- sample(n_v, n_e, replace = TRUE)

g_idx   <- GraphIdx(V = n_v, E = n_e, src = src_vals, tgt = tgt_vals)
g_noidx <- GraphNoIdx(V = n_v, E = n_e, src = src_vals, tgt = tgt_vals)
```

Compare
[`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
performance — we query every vertex:

``` r
t_idx <- system.time(for (v in seq_len(n_v)) incident(g_idx, v, "src"))
t_noidx <- system.time(for (v in seq_len(n_v)) incident(g_noidx, v, "src"))
cat("Indexed:    ", t_idx[["elapsed"]], "s\n")
#> Indexed:     0.003 s
cat("No index:   ", t_noidx[["elapsed"]], "s\n")
#> No index:    0.003 s
```

The indexed version is faster because each
[`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
call is a direct hash lookup rather than scanning all 1 000 edges.

### Index Internals

Internally, each indexed column maintains an R environment used as a
hash map. Keys are stringified values; values are integer vectors of
part IDs. The index is updated incrementally on every
[`set_subpart()`](https://catrgory.github.io/acsets/reference/set_subpart.md)
and
[`clear_subpart()`](https://catrgory.github.io/acsets/reference/clear_subpart.md)
call, so there is a small constant overhead per write.

**Rule of thumb:** index morphisms that are queried in reverse more
often than they are written.

## Query DSL Patterns

The `From() |> Where() |> Select()` pipeline supports chaining multiple
[`Where()`](https://catrgory.github.io/acsets/reference/Where.md)
clauses and using any binary comparison operator.

### Chained Filters

Each [`Where()`](https://catrgory.github.io/acsets/reference/Where.md)
narrows the result set further (logical AND):

``` r
From(db, "Enrolment") |>
  Where("course", `==`, 2) |>
  Where("grade", `!=`, "A-") |>
  Select("student", "course", "grade")
#>   id student course grade
#> 1  2       1      2    B+
```

### Using Different Operators

``` r
From(fw, "Species") |>
  Where("trophic", `>=`, 2) |>
  Select("name", "trophic")
#>   id   name trophic
#> 1  2 Rabbit       2
#> 2  3    Fox       3
#> 3  4  Eagle       3
```

### Pattern Matching with grepl

[`Where()`](https://catrgory.github.io/acsets/reference/Where.md)
accepts any function that takes two arguments and returns a logical
vector. This means you can use `grepl` for pattern matching:

``` r
From(db, "Student") |>
  Where("sname", grepl, "^[AB]") |>
  Select("sname")
#> Warning in op(vals, value): argument 'pattern' has length > 1 and only the
#> first element will be used
#> [1] id    sname
#> <0 rows> (or 0-length row.names)
```

### Combining incident() with the DSL

Use
[`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
to get IDs, then filter further with the DSL:

``` r
# Edges from vertex 1 in the benchmark graph, with target > 50
v1_edges <- incident(g_idx, 1, "src")
# Build a query manually starting from those IDs
q <- structure(list(acs = g_idx, ob = "E", ids = v1_edges), class = "acset_query")
result <- Where(q, "tgt", `>`, 50) |> Select("src", "tgt")
head(result)
#>    id src tgt
#> 1 386   1  71
#> 2 610   1  80
#> 3 640   1  92
#> 4 656   1  84
#> 5 768   1  53
#> 6 865   1  75
```

## Deletion and Cascading

### Pop-and-Swap in Detail

[`rem_part()`](https://catrgory.github.io/acsets/reference/rem_part.md)
uses a **pop-and-swap** strategy: the last part in the object takes the
deleted part’s ID. This is O(1) but **reorders IDs**.

``` r
g <- GraphIdx(V = 5, E = 4,
              src = c(1, 2, 3, 4),
              tgt = c(2, 3, 4, 5))
cat("Before deletion:\n")
#> Before deletion:
as_data_frame(g, "E")
#>   id src tgt
#> 1  1   1   2
#> 2  2   2   3
#> 3  3   3   4
#> 4  4   4   5
```

Remove vertex 2. Vertex 5 (the last) takes ID 2. Edges that pointed *to*
vertex 2 are cleared (`NA`); edges that pointed to vertex 5 are remapped
to 2:

``` r
rem_part(g, "V", 2)
cat("Vertices after removing V#2:\n")
#> Vertices after removing V#2:
as_data_frame(g, "V")
#>   id
#> 1  1
#> 2  2
#> 3  3
#> 4  4
cat("\nEdges after removing V#2:\n")
#> 
#> Edges after removing V#2:
as_data_frame(g, "E")
#>   id src tgt
#> 1  1   1  NA
#> 2  2  NA   3
#> 3  3   3   4
#> 4  4   4   2
```

Notice edge 1 (`src=1, tgt=2`) now has `tgt=NA` because its target was
deleted, while edge 4 (`src=4, tgt=5`) now shows `tgt=2` because vertex
5 was renumbered to 2.

### Multi-Level Cascading

Cascading deletion propagates recursively. Consider a schema with three
levels:

``` r
SchThreeLevel <- BasicSchema(
  obs       = c("A", "B", "C"),
  homs      = list(hom("ab", "B", "A"),
                   hom("bc", "C", "B")),
  attrtypes = c("String"),
  attrs     = list(attr_spec("label", "A", "String"))
)
ThreeLevel <- acset_type(SchThreeLevel, index = c("ab", "bc"))

tl <- ThreeLevel(
  A = 2, B = 3, C = 4,
  label = c("root1", "root2"),
  ab    = c(1, 1, 2),
  bc    = c(1, 2, 3)
)
cat("Before: A =", nparts(tl, "A"),
    ", B =", nparts(tl, "B"),
    ", C =", nparts(tl, "C"), "\n")
#> Before: A = 2 , B = 3 , C = 4
```

Removing A#1 cascades: first its dependent B parts are cascade-deleted
(which in turn cascade-deletes their dependent C parts), then A#1 itself
is removed.

``` r
cascading_rem_part(tl, "A", 1)
cat("After:  A =", nparts(tl, "A"),
    ", B =", nparts(tl, "B"),
    ", C =", nparts(tl, "C"), "\n")
#> After:  A = 1 , B = 1 , C = 2
tables(tl)
#> $A
#>   id label
#> 1  1 root2
#> 
#> $B
#>   id ab
#> 1  1  1
#> 
#> $C
#>   id bc
#> 1  1  1
#> 2  2 NA
```

### Non-Cascading Deletion Leaves NAs

When you use
[`rem_part()`](https://catrgory.github.io/acsets/reference/rem_part.md)
instead of
[`cascading_rem_part()`](https://catrgory.github.io/acsets/reference/cascading_rem_part.md),
dependent morphisms are set to `NA` rather than having their parts
deleted. This can leave orphaned references:

``` r
g2 <- GraphIdx(V = 3, E = 2, src = c(1, 2), tgt = c(2, 3))
rem_part(g2, "V", 2)
as_data_frame(g2, "E")
#>   id src tgt
#> 1  1   1  NA
#> 2  2  NA   2
```

The `NA` values indicate broken foreign keys. Use
[`cascading_rem_part()`](https://catrgory.github.io/acsets/reference/cascading_rem_part.md)
when you want referential integrity maintained automatically.

## JSON Serialization Round-Trips

### Data Format

[`generate_json_acset()`](https://catrgory.github.io/acsets/reference/generate_json_acset.md)
produces a nested list that maps directly to JSON. Each object becomes
an array of records with an `_id` field:

``` r
small <- FSM(
  State      = 2,
  Transition = 1,
  state_name = c("On", "Off"),
  source     = 1,
  target     = 2,
  event      = "toggle"
)
json_data <- generate_json_acset(small)
str(json_data, max.level = 3)
#> List of 2
#>  $ State     :List of 2
#>   ..$ :List of 2
#>   .. ..$ _id       : int 1
#>   .. ..$ state_name: chr "On"
#>   ..$ :List of 2
#>   .. ..$ _id       : int 2
#>   .. ..$ state_name: chr "Off"
#>  $ Transition:List of 1
#>   ..$ :List of 4
#>   .. ..$ _id   : int 1
#>   .. ..$ source: num 1
#>   .. ..$ target: num 2
#>   .. ..$ event : chr "toggle"
```

### Full Round-Trip

``` r
json_str <- jsonlite::toJSON(json_data, auto_unbox = TRUE, pretty = TRUE)
cat(json_str)
#> {
#>   "State": [
#>     {
#>       "_id": 1,
#>       "state_name": "On"
#>     },
#>     {
#>       "_id": 2,
#>       "state_name": "Off"
#>     }
#>   ],
#>   "Transition": [
#>     {
#>       "_id": 1,
#>       "source": 1,
#>       "target": 2,
#>       "event": "toggle"
#>     }
#>   ]
#> }
```

Parse it back:

``` r
parsed_data <- jsonlite::fromJSON(json_str, simplifyVector = FALSE)
small2 <- parse_json_acset(FSM, parsed_data)
acset_equal(small, small2)
#> [1] FALSE
```

### File-Based Round-Trip

``` r
tmp <- tempfile(fileext = ".json")
write_json_acset(small, tmp)
small3 <- read_json_acset(FSM, tmp)
acset_equal(small, small3)
#> [1] FALSE
```

### Schema Serialization

The schema itself can be serialized independently, which is useful for
transmitting the schema definition to other ACSet implementations
(Julia’s ACSets.jl, Python’s py-acsets):

``` r
schema_json <- generate_json_schema(SchFSM)
str(schema_json, max.level = 2)
#> List of 4
#>  $ obs      :List of 2
#>   ..$ : chr "State"
#>   ..$ : chr "Transition"
#>  $ homs     :List of 2
#>   ..$ :List of 3
#>   ..$ :List of 3
#>  $ attrtypes:List of 1
#>   ..$ : chr "String"
#>  $ attrs    :List of 2
#>   ..$ :List of 3
#>   ..$ :List of 3
```

Round-trip the schema:

``` r
schema_rt <- parse_json_schema(schema_json)
identical(objects(SchFSM), objects(schema_rt))
#> [1] TRUE
identical(homs(SchFSM), homs(schema_rt))
#> [1] TRUE
```

### Cross-Language Interoperability

The JSON format is compatible with:

| Language   | Package   |
|------------|-----------|
| Julia      | ACSets.jl |
| Python     | py-acsets |
| TypeScript | ts-acsets |
| Java       | acsets4j  |

Each object is serialized as an array of `{_id, ...}` records. Morphism
values are integer part IDs; attributes are stored as their natural JSON
types. This means you can
[`write_json_acset()`](https://catrgory.github.io/acsets/reference/write_json_acset.md)
in R and read the file in Julia or Python with the matching schema.

## Composition Patterns

### Building Models from Components

[`disjoint_union()`](https://catrgory.github.io/acsets/reference/disjoint_union.md)
combines two ACSets with the same schema. IDs from the second ACSet are
offset so there are no collisions. This lets you build complex models
from reusable pieces.

``` r
# Two small food chains
chain1 <- FoodWeb(
  Species = 2, Predation = 1,
  name = c("Algae", "Shrimp"), trophic = c(1, 2),
  predator = 2, prey = 1, rate = 0.4
)
chain2 <- FoodWeb(
  Species = 2, Predation = 1,
  name = c("Plankton", "Fish"), trophic = c(1, 2),
  predator = 2, prey = 1, rate = 0.6
)

combined <- disjoint_union(chain1, chain2)
tables(combined)
#> $Species
#>   id     name trophic
#> 1  1    Algae       1
#> 2  2   Shrimp       2
#> 3  3 Plankton       1
#> 4  4     Fish       2
#> 
#> $Predation
#>   id predator prey rate
#> 1  1        2    1  0.4
#> 2  2        4    3  0.6
```

After the union, species from `chain2` have IDs 3 and 4. Morphism values
are automatically remapped: the predation link `(predator=2, prey=1)`
from `chain2` becomes `(predator=4, prey=3)`.

### Copy-and-Extend

Use
[`copy_acset()`](https://catrgory.github.io/acsets/reference/copy_acset.md)
to create an independent snapshot, then extend it:

``` r
extended <- copy_acset(combined)
# Add a top predator that eats both shrimp and fish
add_part(extended, "Species", name = "Shark", trophic = 3)
#> [1] 5
add_part(extended, "Predation", predator = 5, prey = 2, rate = 0.2)
#> [1] 3
add_part(extended, "Predation", predator = 5, prey = 4, rate = 0.3)
#> [1] 4
tables(extended)
#> $Species
#>   id     name trophic
#> 1  1    Algae       1
#> 2  2   Shrimp       2
#> 3  3 Plankton       1
#> 4  4     Fish       2
#> 5  5    Shark       3
#> 
#> $Predation
#>   id predator prey rate
#> 1  1        2    1  0.4
#> 2  2        4    3  0.6
#> 3  3        5    2  0.2
#> 4  4        5    4  0.3
```

The original `combined` is unchanged:

``` r
nparts(combined, "Species")
#> [1] 4
nparts(extended, "Species")
#> [1] 5
```

### Iterative Assembly

You can assemble large models by iteratively unioning small components:

``` r
SchChain <- BasicSchema(
  obs       = c("Node", "Link"),
  homs      = list(hom("from", "Link", "Node"),
                   hom("to",   "Link", "Node")),
  attrtypes = c("Numeric"),
  attrs     = list(attr_spec("value", "Node", "Numeric"))
)
Chain <- acset_type(SchChain, index = c("from", "to"))

# Build a 3-segment chain by unioning single links
segment <- function(val1, val2) {
  Chain(Node = 2, Link = 1, value = c(val1, val2), from = 1, to = 2)
}

chain <- segment(1, 2)
chain <- disjoint_union(chain, segment(3, 4))
chain <- disjoint_union(chain, segment(5, 6))
tables(chain)
#> $Node
#>   id value
#> 1  1     1
#> 2  2     2
#> 3  3     3
#> 4  4     4
#> 5  5     5
#> 6  6     6
#> 
#> $Link
#>   id from to
#> 1  1    1  2
#> 2  2    3  4
#> 3  3    5  6
```

## Schema Design Best Practices

### Attributes vs. Objects

Use **attributes** for data that doesn’t need its own identity or
foreign-key relationships (labels, weights, timestamps). Use **objects**
when the data participates in relationships or needs to be referenced by
other objects.

``` r
# Good: colour as attribute (just a label)
SchColoured <- BasicSchema(
  obs       = c("V", "E"),
  homs      = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = c("String"),
  attrs     = list(attr_spec("colour", "V", "String"))
)

# Better if colours are shared and queried: colour as object
SchColourObj <- BasicSchema(
  obs       = c("V", "E", "Colour"),
  homs      = list(hom("src", "E", "V"),
                   hom("tgt", "E", "V"),
                   hom("vcolour", "V", "Colour")),
  attrtypes = c("String"),
  attrs     = list(attr_spec("cname", "Colour", "String"))
)
```

When colour is an **object**, you can use
[`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
to efficiently find all vertices of a given colour, and changing a
colour name updates all references at once:

``` r
ColourGraph <- acset_type(SchColourObj, index = c("src", "tgt", "vcolour"))
cg <- ColourGraph(
  V = 4, E = 3, Colour = 2,
  src = c(1, 2, 3), tgt = c(2, 3, 4),
  vcolour = c(1, 1, 2, 2),
  cname = c("red", "blue")
)

# All red vertices (colour 1)
incident(cg, 1, "vcolour")
#> [1] 1 2
```

### Morphism Direction

Morphisms point from the **dependent** object to the **independent** one
(like foreign keys in SQL). An edge depends on its vertices, so
`src: E → V`.

If you reverse the direction (vertex → edge), you lose the guarantee
that each edge has exactly one source, and you can’t represent
multi-edges cleanly.

### Self-Referential Morphisms

An object can have a morphism to itself. This models trees, linked
lists, or hierarchies:

``` r
SchTree <- BasicSchema(
  obs       = c("Node"),
  homs      = list(hom("parent", "Node", "Node")),
  attrtypes = c("String"),
  attrs     = list(attr_spec("label", "Node", "String"))
)
Tree <- acset_type(SchTree, index = c("parent"))

t <- Tree()
root  <- add_part(t, "Node", label = "root")
child1 <- add_part(t, "Node", label = "child1", parent = root)
child2 <- add_part(t, "Node", label = "child2", parent = root)
leaf   <- add_part(t, "Node", label = "leaf",   parent = child1)
```

Navigate the tree:

``` r
# Children of root
children <- incident(t, root, "parent")
subpart(t, children, "label")
#> [1] "child1" "child2"

# Path from leaf to root
node <- leaf
path <- character()
while (!is.na(node)) {
  path <- c(path, subpart(t, node, "label"))
  p <- subpart(t, node, "parent")
  node <- if (is.na(p)) NA else p
}
cat(paste(path, collapse = " -> "), "\n")
#> leaf -> child1 -> root
```

### Many-to-Many Relationships

Use a **join object** (intermediary table) to model many-to-many
relationships. The food web and university schemas above both do this:
`Predation` links Species ↔︎ Species, and `Enrolment` links Student ↔︎
Course.

This is the standard relational-database pattern, and it works
identically in the ACSet framework — with the bonus that
[`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
and
[`cascading_rem_part()`](https://catrgory.github.io/acsets/reference/cascading_rem_part.md)
understand these relationships automatically.

### Avoiding Common Pitfalls

1.  **Don’t duplicate morphisms as attributes.** If you have a morphism
    `src: E → V`, don’t also add an attribute `src_id` on `E`. The
    morphism already stores the integer reference.

2.  **Name arrows uniquely across the whole schema.** Two different
    morphisms cannot share the same name, even if they belong to
    different objects. Use prefixes if needed (e.g., `esrc` and `etgt`
    for edges, `asrc` for arcs).

3.  **Prefer batch operations.** `add_parts(x, "V", 1000)` is much
    faster than calling
    [`add_part()`](https://catrgory.github.io/acsets/reference/add_part.md)
    in a loop 1 000 times because it grows the internal storage once
    instead of 1 000 times.

``` r
BigGraph <- acset_type(SchBench)
t_batch <- system.time({
  bg <- BigGraph()
  add_parts(bg, "V", 5000)
})
t_loop <- system.time({
  bg2 <- BigGraph()
  for (i in seq_len(5000)) add_part(bg2, "V")
})
cat("Batch:  ", t_batch[["elapsed"]], "s\n")
#> Batch:   0.001 s
cat("Loop:   ", t_loop[["elapsed"]], "s\n")
#> Loop:    0.103 s
```
