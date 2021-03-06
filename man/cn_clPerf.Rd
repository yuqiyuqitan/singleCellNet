% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scn_assess.R
\name{cn_clPerf}
\alias{cn_clPerf}
\title{determine performance of classification at given threshold}
\usage{
cn_clPerf(vect, sampTab, dLevel, classification, thresh,
  dLevelSID = "sample_id")
}
\arguments{
\item{vect}{vector of values}

\item{sampTab}{sample table}

\item{dLevel}{colname}

\item{classification}{actual classification}

\item{thresh}{threshold above which to make a call}

\item{dLevelSID}{column to indicate sample id}
}
\value{
vector of TP FN FP TN
}
\description{
determine performance of classification at given threshold
}
