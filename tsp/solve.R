#!/usr/bin/env Rscript

library(jsonlite)
library(TSP)

solveRoute <- function() {
    ## matrix is the first argument as a 2D JSON array
    args <- commandArgs(trailingOnly = TRUE)
    matrix <- fromJSON(args[1])

    ## make the matrix symmetric (assume driving there and back is equal)
    symmetric <- (t(matrix) + matrix) / 2

    ## TSP library has many possible methods
    methods <- c(
        "nearest_insertion",
        "farthest_insertion",
        "cheapest_insertion",
        "arbitrary_insertion",
        "nn",
        "repetitive_nn",
        "two_opt"
    )

    ## make TSP object
    tsp_dt <- TSP::TSP(as.dist(symmetric), method="euclidean")

    ## try all possible methods of TSP
    dm_tours <- sapply(methods, FUN = function(m) {
        TSP::solve_TSP(tsp_dt, method = m)
    }, simplify = FALSE)

    ## find the best method and use it
    dc <- sort(c(sapply(dm_tours, TSP::tour_length)))
    best <- dm_tours[names(dc)[1]][[1]]
    indices <- as.integer(best) - 1

    print(toJSON(indices))
}

solveRoute()
