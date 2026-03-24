# Create an attribute specification

Create an attribute specification

## Usage

``` r
attr_spec(name, dom, codom)
```

## Arguments

- name:

  Name of the attribute.

- dom:

  Domain object name.

- codom:

  Codomain attribute type name.

## Value

A named list with elements `name`, `dom`, `codom`.

## Examples

``` r
attr_spec("name", "V", "Name")
#> $name
#> [1] "name"
#> 
#> $dom
#> [1] "V"
#> 
#> $codom
#> [1] "Name"
#> 
```
