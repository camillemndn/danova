library(ggplot2)

theme_set(theme_minimal(base_size = 12))

stars_pval <- function(x) {
	stars <- c("***", "**", "*", NULL)
	var <- c(0, 0.01, 0.05, 0.10, 1)
	i <- findInterval(as.numeric(x), var, left.open = T, rightmost.closed = T)
	paste(as.character(x), ifelse(is.na(stars[i]), "", stars[i]))
}

kable_format <- function(tbl) {
	mutate(
		tbl,
		across(
			where(is.numeric),
			function(x) {
				sapply(
					x,
					function(x) format(signif(x, 2), scientific = x < 0.1) |> stars_pval()
				)
			}
		)
	)
}
