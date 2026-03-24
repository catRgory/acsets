# Create an ACSet type bound to a specific schema

Returns a constructor function that creates ACSets with the given
schema. This is the R equivalent of Julia's `@acset_type`.

## Usage

``` r
acset_type(schema, name = NULL, index = character())
```

## Arguments

- schema:

  A BasicSchema

- name:

  Optional name for the type

- index:

  Character vector of morphism/attribute names to index

## Value

A function that creates ACSet instances with this schema

## Examples

``` r
sch <- BasicSchema(
  obs = c("E", "V"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = c("Name"),
  attrs = list(attr_spec("name", "V", "Name"))
)
Graph <- acset_type(sch, index = c("src", "tgt"))

# Create an empty graph
g <- Graph()

# Create a pre-populated graph
g2 <- Graph(V = 3, E = 2, src = c(1L, 2L), tgt = c(2L, 3L),
            name = c("a", "b", "c"))
nparts(g2, "V")
#> [1] 3
```
