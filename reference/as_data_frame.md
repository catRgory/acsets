# Convert ACSet object type to data.frame

Convert ACSet object type to data.frame

## Usage

``` r
as_data_frame(acs, ob)
```

## Arguments

- acs:

  An ACSet.

- ob:

  Character: object type name.

## Value

A data frame with part IDs and subpart columns.

## Examples

``` r
sch <- BasicSchema(
  obs = c("V"),
  attrtypes = c("Name"),
  attrs = list(attr_spec("name", "V", "Name"))
)
g <- ACSet(sch)
add_parts(g, "V", 3, name = c("a", "b", "c"))
#> [1] 1 2 3
as_data_frame(g, "V")
#>   id name
#> 1  1    a
#> 2  2    b
#> 3  3    c
```
