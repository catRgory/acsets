# Start a query on an ACSet object type

Start a query on an ACSet object type

## Usage

``` r
From(acs, ob)
```

## Arguments

- acs:

  An ACSet.

- ob:

  Character: object type to query.

## Value

An `acset_query` object for piping to
[`Where()`](https://catrgory.github.io/acsets/reference/Where.md) and
[`Select()`](https://catrgory.github.io/acsets/reference/Select.md).

## Examples

``` r
sch <- BasicSchema(
  obs = c("V"),
  attrtypes = c("Name", "Age"),
  attrs = list(attr_spec("name", "V", "Name"),
               attr_spec("age", "V", "Age"))
)
g <- ACSet(sch)
add_parts(g, "V", 3, name = c("Alice", "Bob", "Carol"),
          age = c(30, 25, 35))
#> [1] 1 2 3
# Query pipeline: find vertices with age > 28
result <- From(g, "V") |> Where("age", `>`, 28) |> Select("name", "age")
result
#>   id  name age
#> 1  1 Alice  30
#> 2  3 Carol  35
```
