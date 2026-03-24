# Filter query results by a subpart value

Filter query results by a subpart value

## Usage

``` r
Where(query, f, op, value)
```

## Arguments

- query:

  An `acset_query` object from
  [`From()`](https://catrgory.github.io/acsets/reference/From.md).

- f:

  Character: morphism or attribute name.

- op:

  A comparison function (e.g. `==`, `<`).

- value:

  The value to compare against.

## Value

The filtered `acset_query` object.

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
From(g, "V") |> Where("name", `==`, "Bob") |> Select("name")
#>   id name
#> 1  2  Bob
```
