# Generate JSON-compatible list from an ACSet

Generate JSON-compatible list from an ACSet

## Usage

``` r
generate_json_acset(x)
```

## Arguments

- x:

  An ACSet.

## Value

A nested list suitable for JSON serialization.

## Examples

``` r
sch <- BasicSchema(
  obs = c("E", "V"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = c("Name"),
  attrs = list(attr_spec("name", "V", "Name"))
)
Graph <- acset_type(sch)
g <- Graph(V = 2, E = 1, src = 1L, tgt = 2L, name = c("a", "b"))
json_list <- generate_json_acset(g)
str(json_list)
#> List of 2
#>  $ E:List of 1
#>   ..$ :List of 3
#>   .. ..$ _id: int 1
#>   .. ..$ src: int 1
#>   .. ..$ tgt: int 2
#>  $ V:List of 2
#>   ..$ :List of 2
#>   .. ..$ _id : int 1
#>   .. ..$ name: chr "a"
#>   ..$ :List of 2
#>   .. ..$ _id : int 2
#>   .. ..$ name: chr "b"
# Round-trip via JSON
g2 <- parse_json_acset(Graph, json_list)
acset_equal(g, g2)
#> [1] TRUE
```
