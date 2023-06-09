% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/meshes.R
\name{toRGL}
\alias{toRGL}
\title{Conversion to 'rgl' mesh}
\usage{
toRGL(mesh, ...)
}
\arguments{
\item{mesh}{a CGAL mesh, that is to say a list of class \code{"cgalMesh"}
(e.g. an output of the \code{\link{Mesh}} function); in order to be
convertible to a \strong{rgl} mesh, its faces must have at most four sides}

\item{...}{arguments passed to \code{\link[rgl]{mesh3d}}}
}
\value{
A \strong{rgl} mesh, that is to say a list of class \code{"mesh3d"}.
}
\description{
Converts a CGAL mesh (e.g. an output of the \code{\link{Mesh}}
  function) to a \strong{rgl} mesh.
}
\examples{
library(MeshesOperations)
library(rgl)
mesh <- Mesh(
  truncatedIcosahedron[["vertices"]], truncatedIcosahedron[["faces"]],
  triangulate = TRUE, numbersType = "lazyExact"
)
rglmesh <- toRGL(mesh, segments = t(mesh[["edges"]]))
open3d(windowRect = c(50, 50, 562, 562), zoom = 0.9)
shade3d(rglmesh, color = "darkred")
}
