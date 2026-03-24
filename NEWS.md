# acsets 0.1.0

Initial CRAN release of the **acsets** package — Attributed C-Sets for R.

## Features

* **Schemas** (`BasicSchema`): Define the structure of an ACSet with objects
  (tables), morphisms (foreign keys), attribute types, and attributes. Helper
  constructors `hom()` and `attr_spec()` for concise schema definitions.

* **ACSets** (`ACSet`): Mutable in-memory data structures implementing
  attributed C-sets — a category-theoretic generalisation of both graphs and
  data frames. Support for adding, querying, and mutating parts and subparts.

* **Factory constructors** (`acset_type()`, `acset()`): Create reusable
  ACSet constructors bound to a specific schema, with optional declarative
  population via named arguments.

* **Parts and subparts**: `add_part()` / `add_parts()` for adding rows,

  `subpart()` for retrieving values (including composed morphism paths),
  `set_subpart()` / `set_subparts()` for mutation, and `incident()` for
  reverse look-ups.

* **Indexing**: Optional indexing of morphisms and attributes for O(1)
  incident queries.

* **Deletion**: `rem_part()` / `rem_parts()` using an efficient pop-and-swap
  strategy, plus `cascading_rem_part()` / `cascading_rem_parts()` for
  recursive removal of dependent parts.

* **Query DSL**: SQL-inspired pipeline `From() |> Where() |> Select()` for
  filtering and projecting ACSet data into data frames.

* **Disjoint union** (`disjoint_union()`): Combine two ACSets with the same
  schema, automatically offsetting foreign-key references.

* **Deep copy** (`copy_acset()`): Create independent copies of mutable
  ACSets.

* **Table export** (`as_data_frame()`, `tables()`): Convert ACSet object
  types to `data.frame` representations.

* **JSON serialization**: `generate_json_acset()` / `parse_json_acset()` and
  `write_json_acset()` / `read_json_acset()` for interoperability with the
  AlgebraicJulia ecosystem (py-acsets, ts-acsets). Schema serialization via
  `generate_json_schema()` / `parse_json_schema()`.

* **Structural equality** (`acset_equal()`): Compare two ACSets by schema
  and content.

* Built on the **S7** object-oriented class system for robust dispatch and
  property validation.
