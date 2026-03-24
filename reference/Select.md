# Select columns from a query and return a data frame

Select columns from a query and return a data frame

## Usage

``` r
Select(query, ...)
```

## Arguments

- query:

  An `acset_query` object from
  [`From()`](https://catrgory.github.io/acsets/reference/From.md) or
  [`Where()`](https://catrgory.github.io/acsets/reference/Where.md).

- ...:

  Character names of subparts to include as columns.

## Value

A data frame with the selected columns.

## Examples

``` r
sch <- BasicSchema(
  obs = c("V"),
  attrtypes = c("Name"),
  attrs = list(attr_spec("name", "V", "Name"))
)
g <- ACSet(sch)
add_parts(g, "V", 3, name = c("Alice", "Bob", "Carol"))
#> [1] 1 2 3
From(g, "V") |> Select("name")
#>   id  name
#> 1  1 Alice
#> 2  2   Bob
#> 3  3 Carol
```
