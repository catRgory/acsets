# Number of parts of a given object type

Number of parts of a given object type

## Usage

``` r
nparts(x, ...)
```

## Arguments

- x:

  An ACSet.

- ...:

  Arguments passed to methods.

## Value

Integer count of parts.

## Examples

``` r
sch <- BasicSchema(obs = c("V"), homs = list())
g <- ACSet(sch)
add_parts(g, "V", 5)
#> [1] 1 2 3 4 5
nparts(g, "V")
#> [1] 5
```
