# ACSet Schema

A schema describes the structure of an ACSet: its objects (tables),
morphisms (foreign keys), attribute types, and attributes.

## Usage

``` r
BasicSchema(
  obs = character(0),
  homs = list(),
  attrtypes = character(0),
  attrs = list()
)
```

## Arguments

- obs:

  Character vector of object names.

- homs:

  List of morphisms, each a named list with `name`, `dom`, `codom` (all
  character strings referring to elements of `obs`).

- attrtypes:

  Character vector of attribute type names.

- attrs:

  List of attributes, each a named list with `name`, `dom` (an object
  name), `codom` (an attribute type name).

## Value

A `BasicSchema` S7 object.

## Examples

``` r
# A simple graph schema: vertices and edges with source/target morphisms
sch <- BasicSchema(
  obs = c("E", "V"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = c("Name"),
  attrs = list(attr_spec("name", "V", "Name"))
)
objects(sch)
#> [1] "E" "V"
homs(sch)
#> [[1]]
#> [[1]]$name
#> [1] "src"
#> 
#> [[1]]$dom
#> [1] "E"
#> 
#> [[1]]$codom
#> [1] "V"
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "tgt"
#> 
#> [[2]]$dom
#> [1] "E"
#> 
#> [[2]]$codom
#> [1] "V"
#> 
#> 
attrtypes(sch)
#> [1] "Name"
```
