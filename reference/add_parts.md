# Add multiple parts at once

Add multiple parts at once

## Usage

``` r
add_parts(x, ...)
```

## Arguments

- x:

  An ACSet.

- ...:

  Named subpart values, recycled across new parts.

## Value

Integer vector of newly added part IDs.

## Examples

``` r
sch <- BasicSchema(
  obs = c("V"),
  attrtypes = c("Name"),
  attrs = list(attr_spec("name", "V", "Name"))
)
g <- ACSet(sch)
ids <- add_parts(g, "V", 3, name = c("a", "b", "c"))
ids
#> [1] 1 2 3
subpart(g, NULL, "name")
#> [1] "a" "b" "c"
```
