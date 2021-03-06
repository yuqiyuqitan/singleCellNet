% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/grnstatus.R
\name{scn_make_tVals}
\alias{scn_make_tVals}
\title{Estimate gene expression dist in CTs}
\usage{
scn_make_tVals(expDat, sampTab, dLevel = "description1")
}
\arguments{
\item{expDat}{training data}

\item{sampTab, }{### training sample table}

\item{dLevel="description1", }{### column to define CTs}

\item{predictSD=FALSE}{### whether to predict SD based on expression level}
}
\value{
tVals list of ct->mean->named vector of average gene expression, ->sd->named vector of gene standard deviation
}
\description{
Calculate mean and SD
}
