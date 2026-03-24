
# acsets <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/catRgory/acsets/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/catRgory/acsets/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/catRgory/acsets/graph/badge.svg)](https://codecov.io/gh/catRgory/acsets)
<!-- badges: end -->

**Attributed C-Sets for R** — a category-theoretic approach to structured,
relational data.

acsets is an R implementation of Attributed C-Sets (ACSets), the foundational
data structure from [AlgebraicJulia](https://www.algebraicjulia.org/). ACSets
generalise both graphs and data frames into a single, schema-driven abstraction
backed by an efficient in-memory relational store.

## Installation

Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("catRgory/acsets")
```

## Quick example

```r
library(acsets)

# 1. Define a schema — vertices with labels, edges with weights
schema <- BasicSchema(
 obs       = c("V", "E"),
 homs      = list(hom("src", "E", "V"),
                  hom("tgt", "E", "V")),
 attrtypes = c("String", "Numeric"),
 attrs     = list(attr_spec("label",  "V", "String"),
                  attr_spec("weight", "E", "Numeric"))
)

# 2. Create a reusable ACSet constructor (with indexing for fast lookups)
Graph <- acset_type(schema, name = "Graph", index = c("src", "tgt"))

# 3. Instantiate a graph
g <- Graph(
  V = 3, E = 3,
  src    = c(1, 1, 2),
  tgt    = c(2, 3, 3),
  label  = c("A", "B", "C"),
  weight = c(1.0, 1.5, 2.0)
)

# 4. Query — follow a composed path: edge → source vertex → label
subpart(g, 1, c("src", "label"))
#> [1] "A"

# 5. Reverse lookup — which edges target vertex 3?
incident(g, 3, "tgt")
#> [1] 2 3

# 6. SQL-style query — edges with weight > 1.2
From(g, "E") |>
  Where("weight", `>`, 1.2) |>
  Select("src", "tgt", "weight")
#>   id src tgt weight
#> 1  2   1   3    1.5
#> 2  3   2   3    2.0

# 7. View a table as a data frame
as_data_frame(g, "E")
#>   id src tgt weight
#> 1  1   1   2    1.0
#> 2  2   1   3    1.5
#> 3  3   2   3    2.0
```

## Features

- **Schemas** — declare objects, morphisms, attribute types, and attributes
  with `BasicSchema()`.
- **Morphisms** — typed foreign keys between objects, with automatic
  referential-integrity tracking.
- **Attributes** — attach arbitrary R data (strings, numerics, …) to objects.
- **Indexing** — optional hash-based indices on morphisms and attributes for
  O(1) reverse lookups via `incident()`.
- **SQL-style queries** — composable `From() |> Where() |> Select()` pipeline.
- **Path queries** — `subpart(x, part, c("src", "label"))` follows a chain of
  morphisms/attributes in one call.
- **Deletion with cascading** — `rem_part()` uses pop-and-swap;
  `cascading_rem_part()` removes dependents automatically.
- **Disjoint union** — merge two ACSets with `disjoint_union()`, remapping IDs.
- **JSON serialization** — round-trip with `write_json_acset()` /
  `read_json_acset()`, compatible with AlgebraicJulia's JSON format.
- **Reference semantics** — ACSets are mutable; use `copy_acset()` when you
  need an independent copy.

## Vignettes

After installation, browse the vignettes for worked examples:

```r
vignette("acsets")    # Introduction to ACSets
vignette("advanced")  # Advanced ACSet Patterns
```

## Part of the catRgory ecosystem

acsets is one component of **catRgory**, a family of R packages bringing
category-theoretic modelling tools to R:
- **[catlab](https://github.com/catRgory/catlab)** — categories, functors, and
  natural transformations.
- **[algebraicodin](https://github.com/catRgory/algebraicodin)** — categorical
  frameworks for epidemiological models.

## Author

Simon Frost
([@sdwfrost](https://github.com/sdwfrost),
ORCID [0000-0002-5207-9879](https://orcid.org/0000-0002-5207-9879))

## License

MIT © 2026 Simon Frost. See [LICENSE](LICENSE) for details.
