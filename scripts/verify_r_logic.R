# Run from the repository root: Rscript scripts/verify_r_logic.R
# Exercise source functions without rerunning their expensive example analyses.
root <- normalizePath(".")
stopifnot(file.exists(file.path(root, "requirements-python.txt")))

load_functions <- function(path, names) {
  env <- new.env(parent = globalenv())
  for (expr in parse(file.path(root, path))) {
    if (is.call(expr) && as.character(expr[[1]]) %in% c("<-", "=") &&
        is.symbol(expr[[2]]) && as.character(expr[[2]]) %in% names) {
      eval(expr, env)
    }
  }
  stopifnot(all(vapply(names, exists, logical(1), envir = env, inherits = FALSE)))
  env
}

expect_error <- function(expr) {
  stopifnot(inherits(tryCatch(force(expr), error = identity), "error"))
}

test_monopoly <- function() {
  env <- load_functions("Simulación Montecarlo Monopoly/Monopoly.R",
                        c("encontrar_siguiente", "procesar_suerte", "procesar_caja", "simular_monopoly"))
  stopifnot(env$encontrar_siguiente(37, c(6, 16, 26, 36)) == 6,
            env$encontrar_siguiente(8, c(13, 29)) == 13)
  env$sample <- function(...) 10L
  stopifnot(env$procesar_suerte(37) == 34)
  env$sample <- function(...) 1L
  stopifnot(env$procesar_caja(34) == 1)

  # Three doubles send the player to jail. The doubles used to leave jail
  # do not count toward the next three-doubles streak.
  env$procesar_caja <- env$procesar_suerte <- function(pos_actual) pos_actual
  observed <- env$simular_monopoly(6)
  expected <- numeric(40); expected[c(3, 5, 11, 13, 15, 17)] <- 1
  stopifnot(identical(observed, expected))

  # Chance sends the player to jail. Two unsuccessful rolls leave them there;
  # on the third failure they must leave and move by that roll's total.
  env$sample <- local({
    dice <- c(1L, 6L, 1L, 2L, 1L, 2L, 1L, 2L); index <- 0L
    function(...) { index <<- index + 1L; dice[index] }
  })
  env$procesar_suerte <- function(pos_actual) 11L
  expected <- numeric(40); expected[11] <- 3; expected[14] <- 1
  stopifnot(identical(env$simular_monopoly(4), expected))
  for (bad in list(0, -1, 1.5, Inf, NA_real_, c(1, 2))) expect_error(env$simular_monopoly(bad))

  # Original card handlers and RNG: every roll has exactly one final location.
  env <- load_functions("Simulación Montecarlo Monopoly/Monopoly.R",
                        c("encontrar_siguiente", "procesar_suerte", "procesar_caja", "simular_monopoly"))
  set.seed(19)
  observed <- env$simular_monopoly(10000)
  stopifnot(sum(observed) == 10000, observed[31] == 0, all(observed >= 0))
}

test_mds_distances <- function() {
  path <- "MDS and Clustering Kepler Dataset/Code.r"
  env <- load_functions(path, c("calc_pairwise_mahal_sq", "get_matrix_sqrt"))
  x <- rbind(c(0, 0), c(1, 2), c(3, -1), c(-2, 4))
  precision <- solve(matrix(c(2, .3, .3, 1), 2))
  actual <- env$calc_pairwise_mahal_sq(x, precision)
  expected <- vapply(seq_len(nrow(x)), function(i)
    mahalanobis(x, x[i, ], precision, inverted = TRUE), numeric(nrow(x)))
  stopifnot(max(abs(actual - expected)) < 1e-12,
            identical(env$calc_pairwise_mahal_sq(x[1,,drop = FALSE], precision), matrix(0, 1, 1)))
  set.seed(42)
  orthogonal <- qr.Q(qr(matrix(rnorm(16), 4)))
  gram <- orthogonal %*% diag(c(4, 1, 0, -2)) %*% t(orthogonal)
  positive_part <- orthogonal %*% diag(c(4, 1, 0, 0)) %*% t(orthogonal)
  square_root <- env$get_matrix_sqrt(gram)
  stopifnot(max(abs(square_root %*% square_root - positive_part)) < 1e-12)

  # Evaluate the source's actual binary-distance expressions on exact fixtures.
  env$X2_sub <- rbind(c(0, 0), c(0, 0), c(1, 0), c(1, 1))
  env$p_bin <- ncol(env$X2_sub)
  names <- c("a", "d", "b_plus_c", "denom_jac", "S_Jac", "D2_Jac", "denom_dice", "S_Dice", "D2_Dice")
  for (expr in parse(file.path(root, path))) {
    if (is.call(expr) && as.character(expr[[1]]) %in% c("<-", "=") &&
        is.symbol(expr[[2]]) && as.character(expr[[2]]) %in% names) eval(expr, env)
  }
  for (distance in list(env$D2_Jac, env$D2_Dice)) {
    stopifnot(all(is.finite(distance)), identical(distance, t(distance)),
              all(diag(distance) == 0), distance[1, 2] == 0, distance[1, 4] == 1)
  }
  stopifnot(env$D2_Jac[3, 4] == .5, abs(env$D2_Dice[3, 4] - 1/3) < 1e-12)
}

test_rgb_whitening <- function() {
  env <- load_functions("Independent Component Analysis/Second_Approach.R", "findOptimalProjections")
  # Execute the source's preparation statements up to the parallel search.
  # Full-resolution search is verified separately; this fixture checks channel
  # alignment and whitening without repeating 64,800 clustering operations.
  preparation <- function(image) {
    local_env <- new.env(parent = env)
    for (name in names(formals(env$findOptimalProjections))) {
      default <- formals(env$findOptimalProjections)[[name]]
      if (name != "image_path") assign(name, eval(default), local_env)
    }
    local_env$image_path <- "synthetic-rgb-fixture"
    local_env$readImage <- function(...) image
    for (expr in as.list(body(env$findOptimalProjections))[-1]) {
      if (is.call(expr) && as.character(expr[[1]]) %in% c("<-", "=") &&
          identical(expr[[2]], as.name("num_cores"))) break
      eval(expr, local_env)
    }
    local_env
  }
  set.seed(9)
  image <- array(runif(60), c(4, 5, 3))
  result <- preparation(image)
  stopifnot(max(abs(cov(result$Im_Matrix_W) - diag(3))) < 1e-12,
            max(abs(colMeans(result$Im_Matrix_W))) < 1e-12,
            identical(result$Im_Matrix[, 2], as.vector(image[, , 2])))
  restored <- sweep(result$Im_Matrix_W %*% solve(result$W), 2,
                    colMeans(result$Im_Matrix), "+")
  stopifnot(max(abs(restored - result$Im_Matrix)) < 1e-12)
  expect_error(preparation(array(rep(runif(20), 3), c(4, 5, 3))))
}

for (name in c("test_monopoly", "test_mds_distances", "test_rgb_whitening")) {
  invisible(capture.output(get(name)()))
  cat("PASS", name, "\n")
}
cat("3 R behavioral check groups passed.\n")
