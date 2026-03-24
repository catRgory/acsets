# Create a morphism (foreign key) specification

Create a morphism (foreign key) specification

## Usage

``` r
hom(name, dom, codom)
```

## Arguments

- name:

  Name of the morphism.

- dom:

  Domain object name.

- codom:

  Codomain object name.

## Value

A named list with elements `name`, `dom`, `codom`.

## Examples

``` r
hom("src", "E", "V")
#> $name
#> [1] "src"
#> 
#> $dom
#> [1] "E"
#> 
#> $codom
#> [1] "V"
#> 
```
