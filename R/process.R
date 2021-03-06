#' read shape file
#'
#' @importFrom dplyr left_join
#' @importFrom ggplot2 fortify
#' @importFrom maptools readShapePoly
#' @param path  path to shapefile
#' @export
#' @examples
#' states <- read_shape("data-raw/tl_2016_us_state/tl_2016_us_state.shp")
#' states <- states %>% mutate(
#' long = replace(long, long > 100, long[long > 100]-360)
#' )
read_shape <- function(path) {
  stopifnot(file.exists(path))

  dframe <- maptools::readShapePoly(path)
  polys <- ggplot2::fortify(dframe)
  data <- dframe@data
  data$id <- row.names(data)
  dplyr::left_join(polys, data, by="id")
}

#' Scale regions in a map
#'
#' @param map map object as generated by functions such as `process_shape`, `ggplot2::map_data`, or `ggplot2::fortify`
#' @param condition logical expression describing the subset of the map to use for  the scaling
#' @param scale numeric vector of length 2 used to scale the map region in longitude and latitude. Scale factors should be positive (negative values flip region).
#' @param set_to numeric vector of length 2. Set center of the region (defined by range in lat and long) to this longitude and latitude
#' @importFrom dplyr filter mutate
#' @export
#' @examples
#' states <- states %>% group_by(group) %>% mutate(bbox = diff(range(long))*diff(range(lat)))
#' states <- states %>% filter(bbox > 0.15)
#' states %>% ggplot(aes(x = long, y = lat)) + geom_path(aes(group = group))
#' inset <- shift(states, "NAME", "Hawaii", shift_by = c(51, 5.5))
#' inset <- scale(inset, NAME=="Alaska", scale=0.3, set_to=c(-120, 27))
#' inset  %>% ggplot(aes(long, lat)) + geom_path(aes(group=group))
#' inset <- inset  %>%
#'   filter(lat > 20)
#' inset %>%
#'   ggplot(aes(long, lat)) + geom_path(aes(group=group))
#'
#' # Iowa in a Manhattan block design
#' counties %>% filter(STATE == "Iowa") %>%
#'   tidyr::nest(-group) %>%
#'   mutate( data = data %>%
#'   purrr::map(.f = function(x) scale(x, scale=0.8))) %>%
#'   tidyr::unnest(data) %>%
#'   ggplot(aes(x = long, y = lat, group = group)) + geom_polygon()
#'
#' # North Carolina becomes more giraffe-like this way.
#' counties %>% filter(STATE == "North Carolina") %>%
#'   tidyr::nest(-group) %>%
#'   mutate( data = data %>%
#'   purrr::map(.f = function(x) scale(x, scale=0.9))) %>%
#'   tidyr::unnest(data) %>%
#'   ggplot(aes(x = long, y = lat, group = group)) + geom_polygon()
scale <- function(map, condition = NULL, scale = 1, set_to = NULL) {
  stopifnot(!is.null(map$long), !is.null(map$lat))
  long <- lat <- condition__ <- NULL
  map <- data.frame(map)
  conditionCall <- substitute(condition)
  if (!is.null (conditionCall)) {
    map$condition__ <- eval(conditionCall, map)
    submap <- map %>% filter(condition__==TRUE)
  } else {
    submap <- map
  }
  mx <- mean(range(submap$long))
  my <- mean(range(submap$lat))

  scale <- rep(scale, length = 2)
  delta_x <- mx
  delta_y <- my
  if (!is.null(set_to)) {
    set_to <- rep(set_to, length = 2)
    delta_x  <- set_to[1]
    delta_y  <- set_to[2]
  }

  submap <- submap %>% dplyr::mutate(
    long = scale[1]*(long - mx) + delta_x,
    lat = scale[2]*(lat - my) + delta_y
  )

  if (!is.null(conditionCall))  {
    map <- map %>% filter(condition__ != TRUE)
    out_df <- rbind(map, submap) %>% select(-condition__)
  } else {
    out_df <- submap
  }

  out_df
}


#' Shift region on a map
#'
#' @param map map object as generated by `process_shape`  or `ggplot2::map_data`
#' @param condition logical expression describing the subset of the map to use for  the scaling
#' @param shift_by numeric vector of length 2. Relative shift in geographic latitude and longitude.
#' @param set_to numeric vector of length 2. Set center of the region (defined by range in lat and long) to this longitude and latitude
#' @importFrom dplyr mutate filter
#' @export
#' @examples
#' data(states)
#' states %>%
#'   shift(DIVISION == "1", shift_by=c(7.5, 0)) %>%
#'   shift(DIVISION == "2", shift_by=c(5, 0)) %>%
#'   shift(DIVISION == "3", shift_by=c(2.5, 0)) %>%
#'   shift(DIVISION == "5", shift_by=c(5, -1.5)) %>%
#'   shift(DIVISION == "6", shift_by=c(2.5, -1.5)) %>%
#'   shift(DIVISION == "9", shift_by=c(-5, 0)) %>%
#'   shift(DIVISION == "8", shift_by=c(-2.5, 0)) %>%
#'   shift(DIVISION == "7", shift_by=c(0, -1.5)) %>%
#'   filter(lat > 20) %>%
#'   ggplot(aes(long, lat)) + geom_polygon(aes(group=group, fill=factor(DIVISION)))
#'
#' states01 %>%
#'   shift(REGION == "4", shift_by=c(-2.5, 0)) %>%
#'   shift(REGION == "1", shift_by=c(1.25, 0)) %>%
#'   shift(REGION == "3", shift_by=c(0, -1.25)) %>%
#'   filter(lat > 20) %>%
#'   ggplot(aes(long, lat)) + geom_polygon(aes(group=group, fill=factor(REGION)))
shift <- function(map, condition = NULL, shift_by = c(0,0), set_to = NULL) {
  map <- data.frame(map)
  stopifnot(!is.null(map$long), !is.null(map$lat))
  long <- lat <- condition__ <- NULL
  conditionCall <- substitute(condition)

  if (!is.null(conditionCall)) {
    map$condition__ <- eval(conditionCall, map)
    submap <- map %>% filter(condition__==TRUE)
  } else {
    submap = map
  }
  delta_x <- shift_by[1]
  delta_y <- shift_by[2]

  if (!is.null(set_to)) {
    set_to <- rep(set_to, length = 2) # make sure set_to has two elements
    delta_x <- delta_x - mean(range(submap$long)) + set_to[1]
    delta_y <- delta_y - mean(range(submap$lat)) + set_to[2]
  }

  submap <- submap %>% dplyr::mutate(
    long = long + delta_x,
    lat = lat + delta_y
  )

  if (!is.null(conditionCall)) {
    map <- map %>% filter(condition__ != TRUE)
    out_df <- rbind(map, submap) %>% dplyr::select(- condition__)
  } else out_df <- submap

  out_df
}


