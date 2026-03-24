# Disjoint union of two ACSets with the same schema

Disjoint union of two ACSets with the same schema

## Usage

``` r
disjoint_union(x, ...)
```

## Arguments

- x:

  An ACSet.

- ...:

  Arguments passed to methods.

## Value

A new ACSet containing the disjoint union.

## Examples

``` r
sch <- BasicSchema(
  obs = c("E", "V"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
)
Graph <- acset_type(sch)
g1 <- Graph(V = 2, E = 1, src = 1L, tgt = 2L)
g2 <- Graph(V = 2, E = 1, src = 1L, tgt = 2L)
g3 <- disjoint_union(g1, g2)
nparts(g3, "V")
#> [1] 4
nparts(g3, "E")
#> [1] 2
```
