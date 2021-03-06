% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/grnstatus.R
\name{scn_rawScore}
\alias{scn_rawScore}
\title{computes the raw score for a gene as xmax-abs(zscore).}
\usage{
scn_rawScore(vect, mmean, ssd, xmax = 1000)
}
\arguments{
\item{vect}{a vector of gene expression values for multiple samples}

\item{mmean}{mean value in training data}

\item{ssd}{standard deviation in training data}
}
\value{
transformed (but not normalized) GRN score
}
\description{
better values are higher
}
