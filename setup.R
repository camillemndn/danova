knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  dpi = 300,
  fig.height = 12,
  fig.width = 5,
  dev.args = list(bg = "white")
)

library(ggplot2)
theme_set(theme_minimal(base_size = 16))
theme_legend_inside <- theme(
  legend.position = "inside",
  legend.position.inside = c(.05, .25),
  legend.justification = c("left", "bottom"),
  legend.box.just = "left",
  legend.margin = margin(6, 6, 6, 6)
)
theme_legend_inside_right <- theme(
  legend.position = "inside",
  legend.position.inside = c(.95, .95),
  legend.justification = c("right", "top"),
  legend.box.just = "right",
  legend.margin = margin(6, 6, 6, 6)
)

stars_pval <- function(x) {
  stars <- c("***", "**", "*", NULL)
  var <- c(0, 0.01, 0.05, 0.10, 1)
  i <- findInterval(as.numeric(x), var, left.open = T, rightmost.closed = T)
  paste(as.character(x), ifelse(is.na(stars[i]), "", stars[i]))
}

kable_format <- function(tbl) {
  mutate(tbl, across(
    where(is.numeric),
    function(x) {
      sapply(
        x,
        function(x) format(signif(x, 2), scientific = x < 0.1) |> stars_pval()
      )
    }
  ))
}
