#' @title Mesh volume
#' @description Computes the volume bounded by a mesh.
#'
#' @param mesh a mesh given either as a list containing (at least) the two fields 
#'   \code{vertices} (numeric matrix with three columns) and \code{faces} (integer 
#'   matrix or list of integer vectors), otherwise as a \strong{rgl} mesh (i.e. a 
#'   \code{mesh3d} object)
#'
#' @return A number, the volume bounded by the mesh.
#' @export
#'
#' @examples
#' library(MeshesOperations)
#' R <- 4; r <- 2
#' mesh <- torusMesh(R, r)
#' meshVolume(mesh)
#' # true volume of the torus: 
#' 2 * pi^2 * R * r^2
meshVolume <- function(mesh){
  vft <- getVFT(mesh)
  meshVolumeK(vft[["rmesh"]], !vft[["isTriangle"]])
}

#' @title Mesh area
#' @description Computes the surface area a mesh.
#'
#' @param mesh a mesh given either as a list containing (at least) the two fields 
#'   \code{vertices} (numeric matrix with three columns) and \code{faces} (integer 
#'   matrix or list of integer vectors), otherwise as a \strong{rgl} mesh (i.e. a 
#'   \code{mesh3d} object)
#'
#' @return A number, the surface area of the mesh.
#' @export
#'
#' @examples
#' library(MeshesOperations)
#' R <- 4; r <- 2
#' mesh <- torusMesh(R, r)
#' meshArea(mesh)
#' # true area of the torus: 
#' 4 * pi^2 * R * r
meshArea <- function(mesh){
  vft <- getVFT(mesh)
  meshAreaK(vft[["rmesh"]], !vft[["isTriangle"]])
}
