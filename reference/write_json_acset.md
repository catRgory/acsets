# Write an ACSet to JSON file

Write an ACSet to JSON file

## Usage

``` r
write_json_acset(x, path)
```

## Arguments

- x:

  An ACSet.

- path:

  File path to write to.

## Value

The file path, invisibly.

## Examples

``` r
sch <- BasicSchema(obs = c("V"), attrtypes = c("Name"),
                   attrs = list(attr_spec("name", "V", "Name")))
Verts <- acset_type(sch)
g <- Verts(V = 2, name = c("a", "b"))
tmp <- tempfile(fileext = ".json")
write_json_acset(g, tmp)
g2 <- read_json_acset(Verts, tmp)
acset_equal(g, g2)
#> [1] TRUE
unlink(tmp)
```
