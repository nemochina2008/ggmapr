% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/process.R
\name{shift}
\alias{shift}
\title{Shift region on a map}
\usage{
shift(map, condition = NULL, shift_by = c(0, 0), set_to = NULL)
}
\arguments{
\item{map}{map object as generated by `process_shape`  or `ggplot2::map_data`}

\item{condition}{logical expression describing the subset of the map to use for  the scaling}

\item{shift_by}{numeric vector of length 2. Relative shift in geographic latitude and longitude.}

\item{set_to}{numeric vector of length 2. Set center of the region (defined by range in lat and long) to this longitude and latitude}
}
\description{
Shift region on a map
}
\examples{
data(states)
states \%>\%
  shift(DIVISION == "1", shift_by=c(7.5, 0)) \%>\%
  shift(DIVISION == "2", shift_by=c(5, 0)) \%>\%
  shift(DIVISION == "3", shift_by=c(2.5, 0)) \%>\%
  shift(DIVISION == "5", shift_by=c(5, -1.5)) \%>\%
  shift(DIVISION == "6", shift_by=c(2.5, -1.5)) \%>\%
  shift(DIVISION == "9", shift_by=c(-5, 0)) \%>\%
  shift(DIVISION == "8", shift_by=c(-2.5, 0)) \%>\%
  shift(DIVISION == "7", shift_by=c(0, -1.5)) \%>\%
  filter(lat > 20) \%>\%
  ggplot(aes(long, lat)) + geom_polygon(aes(group=group, fill=factor(DIVISION)))

states01 \%>\%
  shift(REGION == "4", shift_by=c(-2.5, 0)) \%>\%
  shift(REGION == "1", shift_by=c(1.25, 0)) \%>\%
  shift(REGION == "3", shift_by=c(0, -1.25)) \%>\%
  filter(lat > 20) \%>\%
  ggplot(aes(long, lat)) + geom_polygon(aes(group=group, fill=factor(REGION)))
}
