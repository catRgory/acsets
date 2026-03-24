# Attributed C-Set

An ACSet is a mutable data structure implementing an attributed C-set (a
functor from a schema category to Set). It generalizes both graphs and
data frames.

## Usage

``` r
ACSet(schema, index = character())
```

## Arguments

- schema:

  A BasicSchema defining the structure.

- index:

  Character vector of morphism/attribute names to index.

## Value

An ACSet S7 object.

## Examples

``` r
sch <- BasicSchema(
  obs = c("E", "V"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = c("Name"),
  attrs = list(attr_spec("name", "V", "Name"))
)
g <- ACSet(sch)
add_parts(g, "V", 3, name = c("a", "b", "c"))
#> [1] 1 2 3
add_part(g, "E", src = 1L, tgt = 2L)
#> [1] 1
nparts(g, "V")
#> [1] 3
subpart(g, 1L, "name")
#> [1] "a"
```
