# Package index

## Schemas

Define the structure of your data

- [`BasicSchema()`](https://catrgory.github.io/acsets/reference/BasicSchema.md)
  : ACSet Schema
- [`attr_spec()`](https://catrgory.github.io/acsets/reference/attr_spec.md)
  : Create an attribute specification
- [`attrtypes()`](https://catrgory.github.io/acsets/reference/attrtypes.md)
  : Get attribute type names from a schema
- [`codom()`](https://catrgory.github.io/acsets/reference/codom.md) :
  Get the codomain of an arrow
- [`dom()`](https://catrgory.github.io/acsets/reference/dom.md) : Get
  the domain of an arrow
- [`hom()`](https://catrgory.github.io/acsets/reference/hom.md) : Create
  a morphism (foreign key) specification
- [`homs()`](https://catrgory.github.io/acsets/reference/homs.md) : Get
  morphisms (foreign keys) from a schema
- [`objects()`](https://catrgory.github.io/acsets/reference/objects.md)
  : Get object names from a schema
- [`types()`](https://catrgory.github.io/acsets/reference/types.md) :
  Get all type names (objects and attribute types)

## ACSets

Create and manipulate attributed C-sets

- [`ACSet()`](https://catrgory.github.io/acsets/reference/ACSet-class.md)
  : Attributed C-Set
- [`acset()`](https://catrgory.github.io/acsets/reference/acset.md) :
  Construct an ACSet using named arguments or NSE
- [`acset_type()`](https://catrgory.github.io/acsets/reference/acset_type.md)
  : Create an ACSet type bound to a specific schema
- [`add_part()`](https://catrgory.github.io/acsets/reference/add_part.md)
  : Add a single part, optionally setting subparts
- [`add_parts()`](https://catrgory.github.io/acsets/reference/add_parts.md)
  : Add multiple parts at once
- [`set_subpart()`](https://catrgory.github.io/acsets/reference/set_subpart.md)
  : Set a single subpart value
- [`set_subparts()`](https://catrgory.github.io/acsets/reference/set_subparts.md)
  : Set multiple subparts at once
- [`clear_subpart()`](https://catrgory.github.io/acsets/reference/clear_subpart.md)
  : Clear a subpart value
- [`copy_acset()`](https://catrgory.github.io/acsets/reference/copy_acset.md)
  : Create a deep copy of an ACSet
- [`disjoint_union()`](https://catrgory.github.io/acsets/reference/disjoint_union.md)
  : Disjoint union of two ACSets with the same schema
- [`gc_acset()`](https://catrgory.github.io/acsets/reference/gc_acset.md)
  : Garbage collection for BitSetParts (no-op for IntParts)
- [`acset_equal()`](https://catrgory.github.io/acsets/reference/acset_equal.md)
  : Test structural equality of two ACSets

## Queries

Query and filter ACSet data

- [`From()`](https://catrgory.github.io/acsets/reference/From.md) :
  Start a query on an ACSet object type
- [`Select()`](https://catrgory.github.io/acsets/reference/Select.md) :
  Select columns from a query and return a data frame
- [`Where()`](https://catrgory.github.io/acsets/reference/Where.md) :
  Filter query results by a subpart value
- [`arrows()`](https://catrgory.github.io/acsets/reference/arrows.md) :
  Get all arrows (morphisms and attributes) from a schema
- [`attrs()`](https://catrgory.github.io/acsets/reference/attrs.md) :
  Get attribute specs from a schema
- [`has_part()`](https://catrgory.github.io/acsets/reference/has_part.md)
  : Check if a part exists
- [`has_subpart()`](https://catrgory.github.io/acsets/reference/has_subpart.md)
  : Check if a subpart (morphism/attribute) exists in the schema
- [`incident()`](https://catrgory.github.io/acsets/reference/incident.md)
  : Incident query: find parts whose subpart equals a given value
- [`maxpart()`](https://catrgory.github.io/acsets/reference/maxpart.md)
  : Maximum part ID for an object type
- [`nparts()`](https://catrgory.github.io/acsets/reference/nparts.md) :
  Number of parts of a given object type
- [`parts()`](https://catrgory.github.io/acsets/reference/parts.md) :
  Get all part IDs for an object type
- [`subpart()`](https://catrgory.github.io/acsets/reference/subpart.md)
  : Get subpart value(s)
- [`tables()`](https://catrgory.github.io/acsets/reference/tables.md) :
  Get all tables from an ACSet

## Serialization

JSON import/export and data frames

- [`generate_json_acset()`](https://catrgory.github.io/acsets/reference/generate_json_acset.md)
  : Generate JSON-compatible list from an ACSet
- [`generate_json_schema()`](https://catrgory.github.io/acsets/reference/generate_json_schema.md)
  : Generate a JSON-compatible list from a schema
- [`parse_json_acset()`](https://catrgory.github.io/acsets/reference/parse_json_acset.md)
  : Parse a JSON-compatible list into an ACSet
- [`parse_json_schema()`](https://catrgory.github.io/acsets/reference/parse_json_schema.md)
  : Parse a JSON-compatible list into a BasicSchema
- [`read_json_acset()`](https://catrgory.github.io/acsets/reference/read_json_acset.md)
  : Read an ACSet from JSON file
- [`write_json_acset()`](https://catrgory.github.io/acsets/reference/write_json_acset.md)
  : Write an ACSet to JSON file
- [`as_data_frame()`](https://catrgory.github.io/acsets/reference/as_data_frame.md)
  : Convert ACSet object type to data.frame

## Deletion

Remove parts with cascading

- [`rem_part()`](https://catrgory.github.io/acsets/reference/rem_part.md)
  : Remove a single part using pop-and-swap strategy
- [`rem_parts()`](https://catrgory.github.io/acsets/reference/rem_parts.md)
  : Remove multiple parts (must be processed from largest to smallest)
- [`cascading_rem_part()`](https://catrgory.github.io/acsets/reference/cascading_rem_part.md)
  : Remove a part and cascade to dependent parts
- [`cascading_rem_parts()`](https://catrgory.github.io/acsets/reference/cascading_rem_parts.md)
  : Remove multiple parts with cascading
