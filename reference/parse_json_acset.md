# Parse a JSON-compatible list into an ACSet

Parse a JSON-compatible list into an ACSet

## Usage

``` r
parse_json_acset(constructor, input)
```

## Arguments

- constructor:

  An acset_constructor from
  [`acset_type()`](https://catrgory.github.io/acsets/reference/acset_type.md).

- input:

  A nested list (typically from JSON) representing ACSet data.

## Value

An ACSet instance.

## Examples

``` r
sch <- BasicSchema(obs = c("V"), attrtypes = c("Name"),
                   attrs = list(attr_spec("name", "V", "Name")))
Verts <- acset_type(sch)
input <- list(V = list(list(`_id` = 1L, name = "a"),
                       list(`_id` = 2L, name = "b")))
g <- parse_json_acset(Verts, input)
nparts(g, "V")
#> [1] 2
```
