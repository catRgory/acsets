# Remove a part and cascade to dependent parts

Remove a part and cascade to dependent parts

## Usage

``` r
cascading_rem_part(x, ...)
```

## Arguments

- x:

  An ACSet.

- ...:

  Arguments passed to methods.

## Value

The ACSet, invisibly.

## Examples

``` r
sch <- BasicSchema(
  obs = c("E", "V"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
)
g <- ACSet(sch, index = c("src", "tgt"))
add_parts(g, "V", 3)
#> [1] 1 2 3
add_parts(g, "E", 2, src = c(1L, 2L), tgt = c(2L, 3L))
#> [1] 1 2
# Removing vertex 2 also removes edges that reference it
cascading_rem_part(g, "V", 2L)
nparts(g, "E")
#> [1] 0
```
