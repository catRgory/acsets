# Changelog

## acsets 0.1.0

Initial CRAN release of the **acsets** package — Attributed C-Sets for
R.

### Features

- **Schemas** (`BasicSchema`): Define the structure of an ACSet with
  objects (tables), morphisms (foreign keys), attribute types, and
  attributes. Helper constructors
  [`hom()`](https://catrgory.github.io/acsets/reference/hom.md) and
  [`attr_spec()`](https://catrgory.github.io/acsets/reference/attr_spec.md)
  for concise schema definitions.

- **ACSets** (`ACSet`): Mutable in-memory data structures implementing
  attributed C-sets — a category-theoretic generalisation of both graphs
  and data frames. Support for adding, querying, and mutating parts and
  subparts.

- **Factory constructors**
  ([`acset_type()`](https://catrgory.github.io/acsets/reference/acset_type.md),
  [`acset()`](https://catrgory.github.io/acsets/reference/acset.md)):
  Create reusable ACSet constructors bound to a specific schema, with
  optional declarative population via named arguments.

- **Parts and subparts**:
  [`add_part()`](https://catrgory.github.io/acsets/reference/add_part.md)
  /
  [`add_parts()`](https://catrgory.github.io/acsets/reference/add_parts.md)
  for adding rows,

  [`subpart()`](https://catrgory.github.io/acsets/reference/subpart.md)
  for retrieving values (including composed morphism paths),
  [`set_subpart()`](https://catrgory.github.io/acsets/reference/set_subpart.md)
  /
  [`set_subparts()`](https://catrgory.github.io/acsets/reference/set_subparts.md)
  for mutation, and
  [`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
  for reverse look-ups.

- **Indexing**: Optional indexing of morphisms and attributes for O(1)
  incident queries.

- **Deletion**:
  [`rem_part()`](https://catrgory.github.io/acsets/reference/rem_part.md)
  /
  [`rem_parts()`](https://catrgory.github.io/acsets/reference/rem_parts.md)
  using an efficient pop-and-swap strategy, plus
  [`cascading_rem_part()`](https://catrgory.github.io/acsets/reference/cascading_rem_part.md)
  /
  [`cascading_rem_parts()`](https://catrgory.github.io/acsets/reference/cascading_rem_parts.md)
  for recursive removal of dependent parts.

- **Query DSL**: SQL-inspired pipeline `From() |> Where() |> Select()`
  for filtering and projecting ACSet data into data frames.

- **Disjoint union**
  ([`disjoint_union()`](https://catrgory.github.io/acsets/reference/disjoint_union.md)):
  Combine two ACSets with the same schema, automatically offsetting
  foreign-key references.

- **Deep copy**
  ([`copy_acset()`](https://catrgory.github.io/acsets/reference/copy_acset.md)):
  Create independent copies of mutable ACSets.

- **Table export**
  ([`as_data_frame()`](https://catrgory.github.io/acsets/reference/as_data_frame.md),
  [`tables()`](https://catrgory.github.io/acsets/reference/tables.md)):
  Convert ACSet object types to `data.frame` representations.

- **JSON serialization**:
  [`generate_json_acset()`](https://catrgory.github.io/acsets/reference/generate_json_acset.md)
  /
  [`parse_json_acset()`](https://catrgory.github.io/acsets/reference/parse_json_acset.md)
  and
  [`write_json_acset()`](https://catrgory.github.io/acsets/reference/write_json_acset.md)
  /
  [`read_json_acset()`](https://catrgory.github.io/acsets/reference/read_json_acset.md)
  for interoperability with the AlgebraicJulia ecosystem (py-acsets,
  ts-acsets). Schema serialization via
  [`generate_json_schema()`](https://catrgory.github.io/acsets/reference/generate_json_schema.md)
  /
  [`parse_json_schema()`](https://catrgory.github.io/acsets/reference/parse_json_schema.md).

- **Structural equality**
  ([`acset_equal()`](https://catrgory.github.io/acsets/reference/acset_equal.md)):
  Compare two ACSets by schema and content.

- Built on the **S7** object-oriented class system for robust dispatch
  and property validation.
