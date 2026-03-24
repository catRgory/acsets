# Construct an ACSet using named arguments or NSE

Construct an ACSet using named arguments or NSE

## Usage

``` r
acset(type, ...)
```

## Arguments

- type:

  An acset_constructor (from acset_type()) or an ACSet class

- ...:

  Named arguments: object names get integer counts, morphism/attribute
  names get value vectors

## Value

An ACSet instance

## Examples

``` r
sch <- BasicSchema(
  obs = c("E", "V"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
)
Graph <- acset_type(sch)
g <- acset(Graph, V = 2, E = 1, src = 1L, tgt = 2L)
nparts(g, "E")
#> [1] 1
```
