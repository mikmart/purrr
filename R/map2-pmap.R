#' Map over multiple inputs simultaneously.
#'
#' These functions are variants of [map()] that iterate over multiple arguments
#' simultaneously. They are parallel in the sense that each input is processed
#' in parallel with the others, not in the sense of multicore computing. They
#' share the same notion of "parallel" as [base::pmax()] and [base::pmin()].
#' `map2()` and `walk2()` are specialised for the two argument case; `pmap()`
#' and `pwalk()` allow you to provide any number of arguments in a list. Note
#' that a data frame is a very important special case, in which case `pmap()`
#' and `pwalk()` apply the function `.f` to each row.
#'
#' Note that arguments to be vectorised over come before `.f`,
#' and arguments that are supplied to every call come after `.f`.
#'
#' @inheritParams map
#' @param .x,.y Vectors of the same length. A vector of length 1 will
#'   be recycled.
#' @param .l A list of vectors, such as a data frame. The length of `.l`
#'   determines the number of arguments that `.f` will be called with. List
#'   names will be used if present.
#' @return An atomic vector, list, or data frame, depending on the suffix.
#'   Atomic vectors and lists will be named if `.x` or the first
#'   element of `.l` is named.
#'
#'   If all input is length 0, the output will be length 0. If any
#'   input is length 1, it will be recycled to the length of the longest.
#' @export
#' @family map variants
#' @examples
#' x <- list(1, 10, 100)
#' y <- list(1, 2, 3)
#' z <- list(5, 50, 500)
#'
#' map2(x, y, ~ .x + .y)
#' # Or just
#' map2(x, y, `+`)
#'
#' pmap(list(x, y, z), sum)
#'
#' # Matching arguments by position
#' pmap(list(x, y, z), function(a, b, c) a / (b + c))
#'
#' # Matching arguments by name
#' l <- list(a = x, b = y, c = z)
#' pmap(l, function(c, b, a) a / (b + c))
#'
#' # Split into pieces, fit model to each piece, then predict
#' by_cyl <- mtcars %>% split(.$cyl)
#' mods <- by_cyl %>% map(~ lm(mpg ~ wt, data = .))
#' map2(mods, by_cyl, predict)
#'
#' # Vectorizing a function over multiple arguments
#' df <- data.frame(
#'   x = c("apple", "banana", "cherry"),
#'   pattern = c("p", "n", "h"),
#'   replacement = c("x", "f", "q"),
#'   stringsAsFactors = FALSE
#'   )
#' pmap(df, gsub)
#' pmap_chr(df, gsub)
#'
#' # Use `...` to absorb unused components of input list .l
#' df <- data.frame(
#'   x = 1:3 + 0.1,
#'   y = 3:1 - 0.1,
#'   z = letters[1:3]
#' )
#' plus <- function(x, y) x + y
#' \dontrun{
#' # this won't work
#' pmap(df, plus)
#' }
#' # but this will
#' plus2 <- function(x, y, ...) x + y
#' pmap_dbl(df, plus2)
#'
#' # The "p" for "parallel" in pmap() is the same as in base::pmin()
#' # and base::pmax()
#' df <- data.frame(
#'   x = c(1, 2, 5),
#'   y = c(5, 4, 8)
#' )
#' # all produce the same result
#' pmin(df$x, df$y)
#' map2_dbl(df$x, df$y, min)
#' pmap_dbl(df, min)
map2 <- function(.x, .y, .f, ...) {
  .f <- as_mapper(.f, ...)
  .Call(map2_impl, environment(), ".x", ".y", ".f", "list")
}
#' @export
#' @rdname map2
map2_lgl <- function(.x, .y, .f, ...) {
  .f <- as_mapper(.f, ...)
  .Call(map2_impl, environment(), ".x", ".y", ".f", "logical")
}
#' @export
#' @rdname map2
map2_int <- function(.x, .y, .f, ...) {
  .f <- as_mapper(.f, ...)
  .Call(map2_impl, environment(), ".x", ".y", ".f", "integer")
}
#' @export
#' @rdname map2
map2_dbl <- function(.x, .y, .f, ...) {
  .f <- as_mapper(.f, ...)
  .Call(map2_impl, environment(), ".x", ".y", ".f", "double")
}
#' @export
#' @rdname map2
map2_chr <- function(.x, .y, .f, ...) {
  .f <- as_mapper(.f, ...)
  .Call(map2_impl, environment(), ".x", ".y", ".f", "character")
}
#' @export
#' @rdname map2
map2_raw <- function(.x, .y, .f, ...) {
  .f <- as_mapper(.f, ...)
  .Call(map2_impl, environment(), ".x", ".y", ".f", "raw")
}
#' @rdname map2
#' @export
map2_dfr <- function(.x, .y, .f, ..., .id = NULL) {
  if (!is_installed("dplyr")) {
    abort("`map2_dfr()` requires dplyr")
  }

  .f <- as_mapper(.f, ...)
  res <- map2(.x, .y, .f, ...)
  dplyr::bind_rows(res, .id = .id)
}
#' @rdname map2
#' @export
map2_dfc <- function(.x, .y, .f, ...) {
  if (!is_installed("dplyr")) {
    abort("`map2_dfc()` requires dplyr")
  }

  .f <- as_mapper(.f, ...)
  res <- map2(.x, .y, .f, ...)
  dplyr::bind_cols(res)
}
#' @rdname map2
#' @export
#' @usage NULL
map2_df <- map2_dfr
#' @export
#' @rdname map2
walk2 <- function(.x, .y, .f, ...) {
  pwalk(list(.x, .y), .f, ...)
  invisible(.x)
}

#' @export
#' @rdname map2
pmap <- function(.l, .f, ...) {
  .f <- as_mapper(.f, ...)
  if (is.data.frame(.l)) {
    .l <- as.list(.l)
  }

  .Call(pmap_impl, environment(), ".l", ".f", "list")
}

#' @export
#' @rdname map2
pmap_lgl <- function(.l, .f, ...) {
  .f <- as_mapper(.f, ...)
  if (is.data.frame(.l)) {
    .l <- as.list(.l)
  }

  .Call(pmap_impl, environment(), ".l", ".f", "logical")
}
#' @export
#' @rdname map2
pmap_int <- function(.l, .f, ...) {
  .f <- as_mapper(.f, ...)
  if (is.data.frame(.l)) {
    .l <- as.list(.l)
  }

  .Call(pmap_impl, environment(), ".l", ".f", "integer")
}
#' @export
#' @rdname map2
pmap_dbl <- function(.l, .f, ...) {
  .f <- as_mapper(.f, ...)
  if (is.data.frame(.l)) {
    .l <- as.list(.l)
  }

  .Call(pmap_impl, environment(), ".l", ".f", "double")
}
#' @export
#' @rdname map2
pmap_chr <- function(.l, .f, ...) {
  .f <- as_mapper(.f, ...)
  if (is.data.frame(.l)) {
    .l <- as.list(.l)
  }

  .Call(pmap_impl, environment(), ".l", ".f", "character")
}
#' @export
#' @rdname map2
pmap_raw <- function(.l, .f, ...) {
  .f <- as_mapper(.f, ...)
  if (is.data.frame(.l)) {
    .l <- as.list(.l)
  }

  .Call(pmap_impl, environment(), ".l", ".f", "raw")
}

#' @rdname map2
#' @export
pmap_dfr <- function(.l, .f, ..., .id = NULL) {
  if (!is_installed("dplyr")) {
    abort("`pmap_dfr()` requires dplyr")
  }

  .f <- as_mapper(.f, ...)
  res <- pmap(.l, .f, ...)
  dplyr::bind_rows(res, .id = .id)
}

#' @rdname map2
#' @export
pmap_dfc <- function(.l, .f, ...) {
  if (!is_installed("dplyr")) {
    abort("`pmap_dfc()` requires dplyr")
  }

  .f <- as_mapper(.f, ...)
  res <- pmap(.l, .f, ...)
  dplyr::bind_cols(res)
}

#' @rdname map2
#' @export
#' @usage NULL
pmap_df <- pmap_dfr

#' @export
#' @rdname map2
pwalk <- function(.l, .f, ...) {
  .f <- as_mapper(.f, ...)
  args_list <- transpose(recycle_args(.l))
  for (args in args_list) {
    do.call(".f", c(args, list(...)))
  }
  invisible(.l)
}
