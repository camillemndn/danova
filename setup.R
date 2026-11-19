library(ggplot2)

theme_set(theme_minimal(base_size = 12))

# LaTeX names for column headers and entries, so the tables use the notation of
# the text rather than the identifiers the packages return.  Keys are matched
# exactly, against column names, character entries, and formatted numbers alike;
# anything absent from the table is left as it is.
latex_labels <- c(
	"p-value" = "$p$-value",
	PC = "$T_{\\operatorname{PC}}$",
	Norm = "$T_{\\text{norm}}$",
	GPF = "$\\operatorname{GPF}$",
	Fmaxb = "$F_{\\max}$",
	CS = "$\\operatorname{CS}$",
	L2B = "$\\operatorname{L^2B}$",
	FB = "$\\operatorname{FB}$",
	region = "Region",
	region1 = "Region 1",
	region2 = "Region 2",
	x = "T (°C)",
	y = "$\\bar\\beta_{g.}(T)$"
)

stars_pval <- function(x) {
	stars <- c("***", "**", "*")
	var <- c(0, 0.01, 0.05, 0.10, 1)
	i <- findInterval(as.numeric(x), var, left.open = T, rightmost.closed = T)
	ifelse(is.na(stars[i]), "", paste0(" ", stars[i]))
}

kable_format <- function(tbl, labels = latex_labels, pval = FALSE) {
	relabel <- function(x) {
		i <- match(x, names(labels))
		ifelse(is.na(i), x, unname(labels)[i])
	}

	tbl |>
		mutate(across(where(is.character), relabel)) |>
		mutate(
			across(
				where(is.numeric),
				function(x) {
					sapply(
						x,
						function(x) {
							format(
								if (pval) signif(x, 2) else x,
								scientific = abs(x < 0.1) & x != 0
							) |>
								relabel() |>
								paste0(if (pval) stars_pval(x) else "")
						}
					)
				}
			)
		) |>
		rename_with(relabel)
}
