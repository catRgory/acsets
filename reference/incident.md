# Incident query: find parts whose subpart equals a given value

Incident query: find parts whose subpart equals a given value

## Usage

``` r
incident(x, ...)
```

## Arguments

- x:

  An ACSet

- ...:

  Arguments passed to methods.

## Examples

``` r
sch <- BasicSchema(
  obs = c("E", "V"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
)
g <- ACSet(sch, index = c("src", "tgt"))
add_parts(g, "V", 3)
#> [1] 1 2 3
add_parts(g, "E", 2, src = c(1L, 1L), tgt = c(2L, 3L))
#> [1] 1 2
# Which edges have source vertex 1?
incident(g, 1L, "src")
#> [1] 1 2
```
