# Column storage with optional indexing ------------------------------------
# A column stores values for a morphism/attribute plus an optional
# reverse-lookup index for efficient incident() queries.
# Columns are environments for mutability (they live inside ACSet's .data env).

# Index choices
INDEX_NONE <- "none"
INDEX_INDEXED <- "indexed"
INDEX_UNIQUE <- "unique"

new_column <- function(index_type = INDEX_NONE, n = 0L) {
  col <- new.env(hash = FALSE, parent = emptyenv())
  col$values <- rep(NA_integer_, n)
  col$defined <- rep(FALSE, n)
  col$index_type <- index_type
  col$index <- NULL
  if (index_type != INDEX_NONE) {
    col$index <- new.env(hash = TRUE, parent = emptyenv())
  }
  col
}

new_attr_column <- function(index_type = INDEX_NONE, n = 0L, default = NA) {
  col <- new.env(hash = FALSE, parent = emptyenv())
  col$values <- rep(default, n)
  col$defined <- rep(FALSE, n)
  col$index_type <- index_type
  col$index <- NULL
  if (index_type != INDEX_NONE) {
    col$index <- new.env(hash = TRUE, parent = emptyenv())
  }
  col
}

# Grow column by n slots
column_grow <- function(col, n) {
  col$values <- c(col$values, rep(NA, n))
  col$defined <- c(col$defined, rep(FALSE, n))
  invisible(col)
}

# Get value at position i
column_get <- function(col, i) {
  col$values[i]
}

# Get multiple values
column_get_multi <- function(col, idx) {
  col$values[idx]
}

# Set value at position i, maintaining index
column_set <- function(col, i, value) {
  old_val <- col$values[i]
  old_defined <- col$defined[i]
  col$values[i] <- value
  col$defined[i] <- TRUE

  if (!is.null(col$index)) {
    # Remove old index entry
    if (old_defined && !is.na(old_val)) {
      key <- as.character(old_val)
      old_preimage <- col$index[[key]]
      if (!is.null(old_preimage)) {
        new_preimage <- old_preimage[old_preimage != i]
        if (length(new_preimage) == 0L) {
          rm(list = key, envir = col$index)
        } else {
          col$index[[key]] <- new_preimage
        }
      }
    }
    # Add new index entry
    if (!is.na(value)) {
      key <- as.character(value)
      existing <- col$index[[key]]
      col$index[[key]] <- c(existing, as.integer(i))
    }
  }
  invisible(col)
}

# Set multiple values at positions idx
column_set_multi <- function(col, idx, values) {
  if (length(values) == 1L) values <- rep(values, length(idx))
  for (k in seq_along(idx)) {
    column_set(col, idx[k], values[k])
  }
  invisible(col)
}

# Clear value at position i
column_clear <- function(col, i) {
  old_val <- col$values[i]
  old_defined <- col$defined[i]
  col$values[i] <- NA
  col$defined[i] <- FALSE

  if (!is.null(col$index) && old_defined && !is.na(old_val)) {
    key <- as.character(old_val)
    old_preimage <- col$index[[key]]
    if (!is.null(old_preimage)) {
      new_preimage <- old_preimage[old_preimage != i]
      if (length(new_preimage) == 0L) {
        rm(list = key, envir = col$index)
      } else {
        col$index[[key]] <- new_preimage
      }
    }
  }
  invisible(col)
}

# Get preimage: which indices have this value?
column_preimage <- function(col, value) {
  if (!is.null(col$index)) {
    key <- as.character(value)
    result <- col$index[[key]]
    if (is.null(result)) integer(0) else result
  } else {
    which(col$values == value)
  }
}

# Rebuild index from scratch (for after bulk operations or gc)
column_rebuild_index <- function(col) {
  if (is.null(col$index)) return(invisible(col))
  # Clear old index
  rm(list = ls(col$index), envir = col$index)
  # Rebuild
  defined_idx <- which(col$defined)
  if (length(defined_idx) > 0L) {
    vals <- col$values[defined_idx]
    non_na <- !is.na(vals)
    if (any(non_na)) {
      groups <- split(defined_idx[non_na], as.character(vals[non_na]))
      for (key in names(groups)) {
        col$index[[key]] <- as.integer(groups[[key]])
      }
    }
  }
  invisible(col)
}

# Swap positions i and j in column (for pop-and-swap deletion)
column_swap <- function(col, i, j) {
  val_i <- col$values[i]
  val_j <- col$values[j]
  def_i <- col$defined[i]
  def_j <- col$defined[j]

  col$values[i] <- val_j
  col$values[j] <- val_i
  col$defined[i] <- def_j
  col$defined[j] <- def_i

  if (!is.null(col$index)) {
    column_rebuild_index(col)
  }
  invisible(col)
}
