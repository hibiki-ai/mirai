# Copyright (C) 2022-2025 Hibiki AI Limited <info@hibiki-ai.com>
#
# This file is part of mirai.
#
# mirai is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# mirai is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# mirai. If not, see <https://www.gnu.org/licenses/>.

# mirai ------------------------------------------------------------------------

#' Daemons (Set Persistent Processes)
#'
#' Set \sQuote{daemons} or persistent background processes to receive
#' \code{\link{mirai}} requests. Specify \sQuote{n} to create daemons on the
#' local machine. Specify \sQuote{url} to receive connections from remote
#' daemons (for distributed computing across the network). Specify
#' \sQuote{remote} to optionally launch remote daemons via a remote
#' configuration. By default, dispatcher ensures optimal scheduling.
#'
#' Use \code{daemons(0)} to reset daemon connections:
#' \itemize{
#'   \item All connected daemons and/or dispatchers exit automatically.
#'   \item \pkg{mirai} reverts to the default behaviour of creating a new
#'   background process for each request.
#'   \item Any unresolved \sQuote{mirai} will return an \sQuote{errorValue} 19
#'   (Connection reset) after a reset.
#'   \item Daemons must be reset before calling \code{daemons} with revised
#'   settings for a compute profile. Daemons may be added at any time by using
#'   \code{\link{launch_local}} or \code{\link{launch_remote}} without needing
#'   to revise daemons settings.
#' }
#'
#' If the host session ends, all connected dispatcher and daemon processes
#' automatically exit as soon as their connections are dropped (unless the
#' daemons were started with \code{autoexit = FALSE}). If a daemon is processing
#' a task, it will exit as soon as the task is complete.
#'
#' To reset persistent daemons started with \code{autoexit = FALSE}, use
#' \code{daemons(NULL)} instead, which also sends exit signals to all connected
#' daemons prior to resetting.
#'
#' For historical reasons, \code{daemons()} with no arguments (other than
#' optionally \sQuote{.compute}) returns the value of \code{\link{status}}.
#'
#' @inheritParams mirai
#' @inheritParams dispatcher
#' @param n integer number of daemons to launch.
#' @param url [default NULL] if specified, a character string comprising a URL
#'   at which to listen for remote daemons, including a port accepting incoming
#'   connections, e.g. 'tcp://hostname:5555' or 'tcp://10.75.32.70:5555'.
#'   Specify a URL with scheme 'tls+tcp://' to use secure TLS connections (for
#'   details see Distributed Computing section below). Auxiliary function
#'   \code{\link{host_url}} may be used to construct a valid host URL.
#' @param remote [default NULL] required only for launching remote daemons, a
#'   configuration generated by \code{\link{remote_config}} or
#'   \code{\link{ssh_config}}.
#' @param dispatcher [default TRUE] logical value, whether to use dispatcher.
#'   Dispatcher runs in a separate process to ensure optimal scheduling,
#'   although this may not always be required (for details see Dispatcher
#'   section below).
#' @param ... (optional) additional arguments passed through to
#'   \code{\link{daemon}} if launching daemons. These include \sQuote{asyncdial},
#'   \sQuote{autoexit}, \sQuote{cleanup}, \sQuote{output}, \sQuote{maxtasks},
#'   \sQuote{idletime} and \sQuote{walltime}.
#' @param seed [default NULL] (optional) supply a random seed (single value,
#'   interpreted as an integer). This is used to inititalise the L'Ecuyer-CMRG
#'   RNG streams sent to each daemon. Note that reproducible results can be
#'   expected only for \code{dispatcher = 'none'}, as the unpredictable timing
#'   of task completions would otherwise influence the tasks sent to each
#'   daemon. Even for \code{dispatcher = 'none'}, reproducibility is not
#'   guaranteed if the order in which tasks are sent is not deterministic.
#' @param serial [default NULL] (optional, requires dispatcher) a configuration
#'   created by \code{\link{serial_config}} to register serialization and
#'   unserialization functions for normally non-exportable reference objects,
#'   such as Arrow Tables or torch tensors.
#' @param tls [default NULL] (optional for secure TLS connections) if not
#'   supplied, zero-configuration single-use keys and certificates are
#'   automatically generated. If supplied, \strong{either} the character path to
#'   a file containing the PEM-encoded TLS certificate and associated private
#'   key (may contain additional certificates leading to a validation chain,
#'   with the TLS certificate first), \strong{or} a length 2 character vector
#'   comprising [i] the TLS certificate (optionally certificate chain) and [ii]
#'   the associated private key.
#'
#' @return The integer number of daemons launched locally (zero if specifying
#'   \sQuote{url} / using a remote launcher).
#'
#' @section Local Daemons:
#'
#' Daemons provide a potentially more efficient solution for asynchronous
#' operations as new processes no longer need to be created on an \emph{ad hoc}
#' basis.
#'
#' Supply the argument \sQuote{n} to set the number of daemons. New background
#' \code{\link{daemon}} processes are automatically created on the local machine
#' connecting back to the host process, either directly or via dispatcher.
#'
#' @section Dispatcher:
#'
#' By default \code{dispatcher = TRUE} launches a background process running
#' \code{\link{dispatcher}}. Dispatcher connects to daemons on behalf of
#' the host, queues tasks, and ensures optimal scheduling.
#'
#' Specifying \code{dispatcher = FALSE}, daemons connect directly to the
#' host and tasks are distributed in a round-robin fashion. As tasks are queued
#' at each daemon, optimal scheduling is not guaranteed as the duration of each
#' task cannot be known \emph{a priori}. Tasks can be queued at one daemon while
#' others remain idle. However, this provides the most resource-light approach,
#' suited to working with similar-length tasks, or where concurrent tasks
#' typically do not exceed available daemons.
#'
#' @section Distributed Computing:
#'
#' Specifying \sQuote{url} as a character string allows tasks to be distributed
#' across the network. \sQuote{n} is not required in this case, and disregarded
#' if supplied.
#'
#' Supply a URL with a \sQuote{tcp://} scheme, such as
#' \sQuote{tcp://10.75.32.70:5555}. The host / dispatcher listens at this
#' address, utilising a single port. Individual daemons (started with
#' \code{\link{daemon}}) may then dial in to this URL. Host / dispatcher
#' automatically adjusts to the number of daemons actually connected, allowing
#' dynamic upscaling or downscaling as required.
#'
#' Switching the URL scheme to \sQuote{tls+tcp://} automatically upgrades the
#' connection to use TLS. The auxiliary function \code{\link{host_url}} may be
#' used to construct a valid host URL based on the computer's hostname.
#'
#' IPv6 addresses are also supported and must be enclosed in square brackets [ ]
#' to avoid confusion with the final colon separating the port. For example,
#' port 5555 on the IPv6 loopback address ::1 would be specified as
#' \sQuote{tcp://[::1]:5555}.
#'
#' Specifying the wildcard value zero for the port number e.g.
#' \sQuote{tcp://[::1]:0} will automatically assign a free ephemeral port. Use
#' \code{\link{status}} to inspect the actual assigned port at any time.
#'
#' Specify \sQuote{remote} with a call to \code{\link{remote_config}} or
#' \code{\link{ssh_config}} to launch daemons on remote machines. Otherwise,
#' \code{\link{launch_remote}} may be used to generate the shell commands to
#' deploy daemons manually on remote resources.
#'
#' @section Compute Profiles:
#'
#' By default, the \sQuote{default} compute profile is used. Providing a
#' character value for \sQuote{.compute} creates a new compute profile with the
#' name specified. Each compute profile retains its own daemons settings, and
#' may be operated independently of each other. Some usage examples follow:
#'
#' \strong{local / remote} daemons may be set with a host URL and specifying
#' \sQuote{.compute} as \sQuote{remote}, which creates a new compute profile.
#' Subsequent \code{\link{mirai}} calls may then be sent for local computation
#' by not specifying the \sQuote{.compute} argument, or for remote computation
#' to connected daemons by specifying the \sQuote{.compute} argument as
#' \sQuote{remote}.
#'
#' \strong{cpu / gpu} some tasks may require access to different types of
#' daemon, such as those with GPUs. In this case, \code{daemons()} may be called
#' to set up host URLs for CPU-only daemons and for those with GPUs, specifying
#' the \sQuote{.compute} argument as \sQuote{cpu} and \sQuote{gpu} respectively.
#' By supplying the \sQuote{.compute} argument to subsequent \code{\link{mirai}}
#' calls, tasks may be sent to either \sQuote{cpu} or \sQuote{gpu} daemons as
#' appropriate.
#'
#' Note: further actions such as resetting daemons via \code{daemons(0)} should
#' be carried out with the desired \sQuote{.compute} argument specified.
#'
#' @examples
#' if (interactive()) {
#' # Only run examples in interactive R sessions
#'
#' # Create 2 local daemons (using dispatcher)
#' daemons(2)
#' status()
#' # Reset to zero
#' daemons(0)
#'
#' # Create 2 local daemons (not using dispatcher)
#' daemons(2, dispatcher = FALSE)
#' status()
#' # Reset to zero
#' daemons(0)
#'
#' # Set up dispatcher accepting TLS over TCP connections
#' daemons(url = host_url(tls = TRUE))
#' status()
#' # Reset to zero
#' daemons(0)
#'
#' # Set host URL for remote daemons to dial into
#' daemons(url = host_url(), dispatcher = FALSE)
#' status()
#' # Reset to zero
#' daemons(0)
#'
#' # Use with() to evaluate with daemons for the duration of the expression
#' with(
#'   daemons(2),
#'   {
#'     m1 <- mirai(Sys.getpid())
#'     m2 <- mirai(Sys.getpid())
#'     cat(m1[], m2[], "\n")
#'   }
#' )
#'
#' }
#'
#' \dontrun{
#' # Launch daemons on remotes 'nodeone' and 'nodetwo' using SSH
#' # connecting back directly to the host URL over a TLS connection:
#'
#' daemons(n = 1L,
#'         url = host_url(tls = TRUE),
#'         remote = ssh_config(c('ssh://nodeone', 'ssh://nodetwo')),
#'         dispatcher = FALSE)
#'
#' # Launch 4 daemons on the remote machine 10.75.32.90 using SSH tunnelling
#' # over port 5555 ('url' hostname must be '127.0.0.1'):
#'
#' daemons(n = 4L,
#'         url = 'tcp://127.0.0.1:5555',
#'         remote = ssh_config('ssh://10.75.32.90', tunnel = TRUE, port = 5555))
#'
#' }
#'
#' @export
#'
daemons <- function(n, url = NULL, remote = NULL, dispatcher = TRUE, ...,
                    seed = NULL, serial = NULL, tls = NULL, pass = NULL,
                    .compute = "default") {

  missing(n) && missing(url) && return(status(.compute))

  envir <- ..[[.compute]]

  if (is.character(url)) {

    if (is.null(envir)) {
      envir <- init_envir_stream(seed)
      launches <- 0L
      dots <- parse_dots(...)
      output <- attr(dots, "output")
      switch(
        parse_dispatcher(dispatcher),
        {
          tls <- configure_tls(url, tls, pass, envir)
          sock <- req_socket(url, tls = tls)
          check_store_url(sock, envir)
        },
        {
          tls <- configure_tls(url, tls, pass, envir, returnconfig = FALSE)
          cv <- cv()
          urld <- local_url()
          sock <- req_socket(urld)
          res <- launch_sync_dispatcher(sock, wa5(urld, dots, url), output, tls, pass, serial)
          is.object(res) && stop(._[["sync_dispatcher"]])
          store_dispatcher(sock, res, cv, envir)
          `[[<-`(envir, "msgid", 0L)
        },
        stop(._[["dispatcher_args"]])
      )
      `[[<-`(.., .compute, `[[<-`(`[[<-`(`[[<-`(envir, "sock", sock), "n", launches), "dots", dots))
      if (length(remote))
        launch_remote(n = n, remote = remote, tls = envir[["tls"]], ..., .compute = .compute)
    } else {
      stop(sprintf(._[["daemons_set"]], .compute))
    }

  } else {

    signal <- is.null(n)
    if (signal) n <- 0L
    is.numeric(n) || stop(._[["numeric_n"]])
    n <- as.integer(n)

    if (n == 0L) {
      is.null(envir) && return(0L)

      if (signal) send_signal(envir)
      reap(envir[["sock"]])
      ..[[.compute]] <- NULL -> envir

    } else if (is.null(envir)) {

      n > 0L || stop(._[["n_zero"]])
      envir <- init_envir_stream(seed)
      urld <- local_url()
      dots <- parse_dots(...)
      output <- attr(dots, "output")
      switch(
        parse_dispatcher(dispatcher),
        {
          sock <- req_socket(urld)
          launch_sync_daemons(seq_len(n), sock, urld, dots, envir, output) || stop(._[["sync_daemons"]])
          `[[<-`(envir, "urls", urld)
        },
        {
          cv <- cv()
          sock <- req_socket(urld)
          res <- launch_sync_dispatcher(sock, wa4(urld, dots, envir[["stream"]], n), output, serial = serial)
          is.object(res) && stop(._[["sync_dispatcher"]])
          store_dispatcher(sock, res, cv, envir)
          for (i in seq_len(n)) next_stream(envir)
          `[[<-`(envir, "msgid", 0L)
        },
        stop(._[["dispatcher_args"]])
      )
      `[[<-`(.., .compute, `[[<-`(`[[<-`(`[[<-`(envir, "sock", sock), "n", n), "dots", dots))
    } else {
      stop(sprintf(._[["daemons_set"]], .compute))
    }

  }

  is.null(envir) && return(0L)
  `class<-`(envir[["n"]], c("miraiDaemons", .compute))

}

#' @export
#'
print.miraiDaemons <- function(x, ...) print(unclass(x))

#' With Mirai Daemons
#'
#' Evaluate an expression with daemons that last for the duration of the
#' expression. Ensure each mirai within the statement is explicitly called (or
#' their values collected) so that daemons are not reset before they have all
#' completed.
#'
#' This function is an S3 method for the generic \code{with} for class
#' 'miraiDaemons'.
#'
#' @param data a call to \code{\link{daemons}}.
#' @param expr an expression to evaluate.
#' @param ... not used.
#'
#' @return The return value of \sQuote{expr}.
#'
#' @examples
#' if (interactive()) {
#' # Only run examples in interactive R sessions
#'
#' with(
#'   daemons(2, dispatcher = FALSE),
#'   {
#'     m1 <- mirai(Sys.getpid())
#'     m2 <- mirai(Sys.getpid())
#'     cat(m1[], m2[], "\n")
#'   }
#' )
#'
#' status()
#'
#' }
#'
#' @export
#'
with.miraiDaemons <- function(data, expr, ...) {

  on.exit(daemons(0L, .compute = class(data)[2L]))
  expr

}

#' Status Information
#'
#' Retrieve status information for the specified compute profile, comprising
#' current connections and daemons status.
#'
#' @param .compute [default 'default'] character compute profile (each compute
#'   profile has its own set of daemons for connecting to different resources).
#'
#'   \strong{or} a \sQuote{miraiCluster} to obtain its status.
#'
#' @return A named list comprising:
#'   \itemize{
#'     \item \strong{connections} - integer number of active daemon connections.
#'     \item \strong{daemons} - character URL at which host / dispatcher is
#'     listening, or else \code{0L} if daemons have not yet been set.
#'     \item \strong{mirai} (present only if using dispatcher) - a named integer
#'     vector comprising: \strong{awaiting} - number of tasks queued for
#'     execution at dispatcher, \strong{executing} - number of tasks sent to a
#'     daemon for execution, and \strong{completed} - number of tasks for which
#'     the result has been received (either completed or cancelled).
#'   }
#'
#' @section Events:
#'
#'   If dispatcher is used combined with daemon IDs, an additional element
#'   \strong{events} will report the positive integer ID when the daemon
#'   connects and the negative value when it disconnects. Only the events since
#'   the previous status query are returned.
#'
#' @examples
#' if (interactive()) {
#' # Only run examples in interactive R sessions
#'
#' status()
#' daemons(url = "tcp://[::1]:0")
#' status()
#' daemons(0)
#'
#' }
#'
#' @export
#'
status <- function(.compute = "default") {

  is.list(.compute) && return(status(attr(.compute, "id")))
  envir <- ..[[.compute]]
  is.null(envir) && return(list(connections = 0L, daemons = 0L))
  length(envir[["msgid"]]) && return(dispatcher_status(envir))
  list(connections = as.integer(stat(envir[["sock"]], "pipes")), daemons = envir[["urls"]])

}

#' Create Serialization Configuration
#'
#' Returns a serialization configuration, which may be set to perform custom
#' serialization and unserialization of normally non-exportable reference
#' objects, allowing these to be used seamlessly between different R sessions.
#' This feature utilises the 'refhook' system of R native serialization. Once
#' set, the functions apply to all mirai requests for a specific compute
#' profile.
#'
#' @param class character string of the class of object custom serialization
#'   functions are applied to, e.g. \sQuote{ArrowTabular} or
#'   \sQuote{torch_tensor}.
#' @param sfunc a function that accepts a reference object inheriting from
#'   \sQuote{class} (or a list of such objects) and returns a raw vector.
#' @param ufunc a function that accepts a raw vector and returns a reference
#'   object (or list of such objects).
#' @param vec [default FALSE] whether or not the serialization functions are
#'   vectorized. If FALSE, they should accept and return reference objects
#'   individually e.g. \code{arrow::write_to_raw} and
#'   \code{arrow::read_ipc_stream}. If TRUE, they should accept and return a
#'   list of reference objects, e.g. \code{torch::torch_serialize} and
#'   \code{torch::torch_load}.
#'
#' @return A list comprising the configuration. This should be passed to the
#'   \sQuote{serial} argument of \code{\link{daemons}}.
#'
#' @examples
#' cfg <- serial_config("test_cls", function(x) serialize(x, NULL), unserialize)
#' cfg
#'
#' @export
#'
serial_config <- serial_config

# internals --------------------------------------------------------------------

configure_tls <- function(url, tls, pass, envir, returnconfig = TRUE) {
  purl <- parse_url(url)
  sch <- purl[["scheme"]]
  if ((startsWith(sch, "wss") || startsWith(sch, "tls")) && is.null(tls)) {
    cert <- write_cert(cn = purl[["hostname"]])
    `[[<-`(envir, "tls", cert[["client"]])
    tls <- cert[["server"]]
  }
  cfg <- if (length(tls)) tls_config(server = tls, pass = pass)
  returnconfig || return(tls)
  cfg
}

init_envir_stream <- function(seed) {
  .advance()
  oseed <- .GlobalEnv[[".Random.seed"]]
  RNGkind("L'Ecuyer-CMRG")
  if (length(seed)) set.seed(seed)
  envir <- `[[<-`(new.env(hash = FALSE, parent = ..), "stream", .GlobalEnv[[".Random.seed"]])
  `[[<-`(.GlobalEnv, ".Random.seed", oseed)
  envir
}

req_socket <- function(url, tls = NULL, resend = 0L)
  `opt<-`(socket("req", listen = url, tls = tls), "req:resend-time", resend)

parse_dispatcher <- function(x)
  if (is.logical(x)) 1L + (!is.na(x) && x) else if (x == "process" || x == "thread") 2L else if (x == "none") 1L else 3L

parse_dots <- function(...) {
  ...length() || return("")
  dots <- list(...)
  dots <- dots[as.logical(lapply(dots, function(x) is.logical(x) || is.numeric(x)))]
  length(dots) || return("")
  dnames <- names(dots)
  out <- sprintf(",%s", paste(dnames, dots, sep = "=", collapse = ","))
  is.logical(dots[["output"]]) && dots[["output"]] && return(`attr<-`(out, "output", ""))
  out
}

parse_tls <- function(tls)
  switch(length(tls) + 1L, "", sprintf(",tls=\"%s\"", tls), sprintf(",tls=c(\"%s\",\"%s\")", tls[1L], tls[2L]))

libp <- function(lp = .libPaths()) lp[file.exists(file.path(lp, "mirai"))][1L]

wa2 <- function(url, dots, rs, tls = NULL)
  shQuote(sprintf("mirai::daemon(\"%s\",dispatcher=FALSE%s%s,rs=c(%s))", url, dots, parse_tls(tls), paste0(rs, collapse = ",")))

wa3 <- function(url, dots, rs, tls = NULL)
  shQuote(sprintf("mirai::daemon(\"%s\",dispatcher=TRUE%s%s,rs=c(%s))", url, dots, parse_tls(tls), paste0(rs, collapse = ",")))

wa4 <- function(urld, dots, rs, n)
  shQuote(sprintf(".libPaths(c(\"%s\",.libPaths()));mirai::dispatcher(\"%s\",n=%d,rs=c(%s)%s)", libp(), urld, n, paste0(rs, collapse= ","), dots))

wa5 <- function(urld, dots, url)
  shQuote(sprintf(".libPaths(c(\"%s\",.libPaths()));mirai::dispatcher(\"%s\",url=\"%s\"%s)", libp(), urld, url, dots))

launch_daemon <- function(args, output)
  system2(.command, args = c("-e", args), stdout = output, stderr = output, wait = FALSE)

query_dispatcher <- function(sock, command, send_mode = 2L, recv_mode = 5L, block = .limit_short)
  if (r <- send(sock, command, mode = send_mode, block = block)) r else
    recv(sock, mode = recv_mode, block = block)

launch_sync_dispatcher <- function(sock, args, output, tls = NULL, pass = NULL, serial = NULL) {
  pkgs <- Sys.getenv("R_DEFAULT_PACKAGES")
  system2(.command, args = c("--default-packages=NULL", "--vanilla", "-e", args), stdout = output, stderr = output, wait = FALSE)
  if (is.list(serial))
    `opt<-`(sock, "serial", serial)
  query_dispatcher(sock, list(pkgs, tls, pass, serial), send_mode = 1L, recv_mode = 2L, block = .limit_long)
}

launch_sync_daemons <- function(seq, sock, urld, dots, envir, output) {
  cv <- cv()
  pipe_notify(sock, cv = cv, add = TRUE)
  for (i in seq)
    launch_daemon(wa2(urld, dots, next_stream(envir)), output)
  for (i in seq)
    until(cv, .limit_long) || return(pipe_notify(sock, cv = NULL, add = TRUE))
  !pipe_notify(sock, cv = NULL, add = TRUE)
}

store_dispatcher <- function(sock, res, cv, envir)
  `[[<-`(`[[<-`(`[[<-`(`[[<-`(envir, "sock", sock), "urls", res[-1L]), "pid", as.integer(res[1L])), "cv", cv)

sub_real_port <- function(port, url) sub("(?<=:)0(?![^/])", port, url, perl = TRUE)

check_store_url <- function(sock, envir) {
  listener <- attr(sock, "listener")[[1L]]
  url <- opt(listener, "url")
  if (parse_url(url)[["port"]] == "0")
    url <- sub_real_port(opt(listener, "tcp-bound-port"), url)
  `[[<-`(envir, "urls", url)
}

send_signal <- function(envir) {
  signals <- if (is.null(envir[["msgid"]])) stat(envir[["sock"]], "pipes") else
    query_dispatcher(envir[["sock"]], c(0L, 0L))[1L]
  for (i in seq_len(signals)) {
    send(envir[["sock"]], ._scm_., mode = 2L)
    msleep(10L)
  }
}

dispatcher_status <- function(envir) {
  status <- query_dispatcher(envir[["sock"]], c(0L, 0L))
  is.object(status) && return(status)
  out <- list(connections = status[1L],
              daemons = envir[["urls"]],
              mirai = c(awaiting = status[2L],
                        executing = status[3L],
                        completed = envir[["msgid"]] - status[2L] - status[3L]))
  if (length(status) > 3L)
    out <- c(out, list(events = status[4:length(status)]))
  out
}

._scm_. <- as.raw(c(0x42, 0x0a, 0x03, 0x00, 0x00, 0x00, 0x02, 0x03, 0x04, 0x00, 0x00, 0x05, 0x03, 0x00, 0x05, 0x00, 0x00, 0x00, 0x55, 0x54, 0x46, 0x2d, 0x38, 0xfc, 0x00, 0x00, 0x00))
