#' @title Connected components of a 3D mesh
#' @description Computes the connected components of a 3D mesh; for each
#'   returned component, its faces are coherently oriented, its normals are
#'   computed if desired, and it is triangulated if desired.
#'
#' @param vertices a numeric matrix with three columns, or a \code{bigq}
#'   matrix with three columns if \code{numbersType="gmp"}
#' @param faces either an integer matrix (each row provides the vertex indices
#'   of the corresponding face) or a list of integer vectors, each one
#'   providing the vertex indices of the corresponding face
#' @param mesh if not \code{NULL}, this argument takes precedence over
#'   \code{vertices} and \code{faces}, and must be either a list containing
#'   the fields \code{vertices} and \code{faces} (objects as described above),
#'   otherwise a \strong{rgl} mesh (i.e. a \code{mesh3d} object)
#' @param triangulate Boolean, whether to triangulate the faces
#' @param clean Boolean, whether to clean the mesh (merging duplicated
#'   vertices, duplicated faces, removed isolated vertices)
#' @param normals Boolean, whether to compute the normals
#' @param numbersType the type of the numbers used in C++ for the
#'   computations; must be one of \code{"double"}, \code{"lazyExact"}
#'   (a type provided by CGAL for exact computations), or \code{"gmp"}
#'   (exact computations with rational numbers); using exact computations can
#'   improve the detection of the exterior edges
#'
#' @return A list of meshes, the connected components, each one being
#'   represented as the output of the \code{\link{Mesh}} function.
#'
#' @export
#'
#' @importFrom gmp as.bigq asNumeric
#' @importFrom data.table uniqueN
#'
#' @examples
#' library(MeshesOperations)
#' library(rgl)
#'
#' # a tetrahedron with ill-oriented faces ####
#' vertices1 <- rbind(
#'   c(-1, -1, -1),
#'   c( 1,  1, -1),
#'   c( 1, -1,  1),
#'   c(-1,  1,  1)
#' )
#' faces1 <- rbind(
#'   c(1, 2, 3),
#'   c(3, 4, 2),
#'   c(4, 2, 1),
#'   c(4, 3, 1)
#' )
#' # same tetrahedron translated ####
#' vertices2 <- vertices1 + 3
#' # merge the two tetrahedra ####
#' vertices <- rbind(vertices1, vertices2)
#' faces <- rbind(faces1, faces1 + 4)
#'
#' # now run the `connectedComponents` function ####
#' meshes <- connectedComponents(vertices, faces, normals = FALSE)
#' mesh1 <- meshes[[1]]; mesh2 <- meshes[[2]]
#' # plot
#' tmesh1 <- toRGL(mesh1)
#' tmesh2 <- toRGL(mesh2)
#' open3d(windowRect = c(50, 50, 562, 562))
#' shade3d(tmesh1, color = "green", back = "culled")
#' shade3d(tmesh2, color = "red", back = "culled")
connectedComponents <- function(
  vertices, faces, mesh = NULL, triangulate = FALSE, clean = FALSE,
	normals = FALSE, numbersType = "double"
){
  numbersType <- match.arg(numbersType, c("double", "lazyExact", "gmp"))
  gmp <- numbersType == "gmp"
  if(!is.null(mesh)){
	if(inherits(mesh, "mesh3d")){
	  vft  <- getVFT(mesh, beforeCheck = TRUE)
	  mesh <- vft[["rmesh"]]
	}
	vertices <- mesh[["vertices"]]
	faces    <- mesh[["faces"]]
  }
  checkedMesh <- checkMesh(vertices, faces, gmp = gmp, aslist = TRUE)
  vertices         <- checkedMesh[["vertices"]]
  faces            <- checkedMesh[["faces"]]
  homogeneousFaces <- checkedMesh[["homogeneousFaces"]]
  isTriangle       <- checkedMesh[["isTriangle"]]
  rmesh <- list("vertices" = vertices, "faces" = faces)
  if(numbersType == "double"){
    ccmeshes <- connectedComponentsK(
      rmesh, isTriangle, triangulate, clean, normals
    )
  }else if(numbersType == "lazyExact"){
    ccmeshes <- connectedComponentsEK(
      rmesh, isTriangle, triangulate, clean, normals
    )
  }else{
    ccmeshes <- connectedComponentsQ(
      rmesh, isTriangle, triangulate, clean, normals
    )
  }
  if(triangulate && isTriangle){
    message(
      "Ignored option `triangulate`, since the mesh is already triangle."
    )
    triangulate <- FALSE
  }
  ncc <- length(ccmeshes)
  meshes <- vector("list", ncc)
  for(i in seq_len(ncc)){
    mesh <- ccmeshes[[i]]
    if(gmp){
      vertices <- as.bigq(t(mesh[["vertices"]]))
      mesh[["gmpVertices"]] <- vertices
      vertices <- asNumeric(vertices)
    }else{
      vertices <- t(mesh[["vertices"]])
    }
    mesh[["vertices"]] <- vertices
    edgesDF <- mesh[["edges"]]
    mesh[["edgesDF"]] <- edgesDF
    mesh[["edges"]] <- as.matrix(edgesDF[, c("i1", "i2")])
    exteriorEdges <- as.matrix(subset(edgesDF, exterior)[, c("i1", "i2")])
    mesh[["exteriorEdges"]] <- exteriorEdges
    mesh[["exteriorVertices"]] <- which(table(exteriorEdges) != 2L)
    if(normals){
      mesh[["normals"]] <- t(mesh[["normals"]])
    }
    if(triangulate){
      edges0DF <- mesh[["edges0"]]
      mesh[["edges0DF"]] <- edges0DF
      mesh[["edges0"]] <- as.matrix(edges0DF[, c("i1", "i2")])
      if(normals){
        mesh[["normals0"]] <- t(mesh[["normals0"]])
      }
    }
    if(triangulate || homogeneousFaces){
      mesh[["faces"]] <- do.call(rbind, mesh[["faces"]])
      toRGL <- ifelse(triangulate, 3L, homogeneousFaces)
    }else{
      sizes <- lengths(mesh[["faces"]])
      usizes <- uniqueN(sizes)
      if(usizes == 1L){
        if(sizes[1L] %in% c(3L, 4L)){
          toRGL <- sizes[1L]
        }
        mesh[["faces"]] <- do.call(rbind, mesh[["faces"]])
      }else if(usizes == 2L && all(sizes %in% c(3L, 4L))){
        toRGL <- 34L
      }else{
        toRGL <- FALSE
      }
    }
    attr(mesh, "toRGL") <- toRGL
    class(mesh) <- "cgalMesh"
    meshes[[i]] <- mesh
  }
  meshes
}
