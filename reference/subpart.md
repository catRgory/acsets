# Get subpart value(s)

Get subpart value(s)

## Usage

``` r
subpart(x, ...)
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
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = c("Name"),
  attrs = list(attr_spec("name", "V", "Name"))
)
g <- ACSet(sch)
add_parts(g, "V", 3, name = c("a", "b", "c"))
#> [1] 1 2 3
add_part(g, "E", src = 1L, tgt = 2L)
#> [1] 1
# Single value
subpart(g, 1L, "src")
#> [1] 1
# All values
subpart(g, NULL, "name")
#> [1] "a" "b" "c"
# Composed path: source vertex name of edge 1
subpart(g, 1L, c("src", "name"))
#> [1] "a"
```
