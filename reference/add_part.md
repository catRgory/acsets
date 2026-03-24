# Add a single part, optionally setting subparts

Add a single part, optionally setting subparts

## Usage

``` r
add_part(x, ...)
```

## Arguments

- x:

  An ACSet.

- ...:

  Named subpart values to set on the new part.

## Value

Integer ID of the newly added part.

## Examples

``` r
sch <- BasicSchema(
  obs = c("E", "V"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
)
g <- ACSet(sch)
add_part(g, "V")
#> [1] 1
add_part(g, "V")
#> [1] 2
add_part(g, "E", src = 1L, tgt = 2L)
#> [1] 1
subpart(g, 1L, "src")
#> [1] 1
```
