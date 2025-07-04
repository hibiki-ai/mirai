% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dispatcher.R
\name{dispatcher}
\alias{dispatcher}
\title{Dispatcher}
\usage{
dispatcher(host, url = NULL, n = NULL, ..., tls = NULL, pass = NULL, rs = NULL)
}
\arguments{
\item{host}{the character URL dispatcher should dial in to, typically an IPC
address.}

\item{url}{(optional) the character URL dispatcher should listen at (and
daemons should dial in to), including the port to connect to e.g.
'tcp://hostname:5555' or 'tcp://10.75.32.70:5555'. Specify 'tls+tcp://' to
use secure TLS connections.}

\item{n}{(optional) if specified, the integer number of daemons to launch. In
this case, a local url is automatically generated.}

\item{...}{(optional) additional arguments passed through to \code{\link[=daemon]{daemon()}}.
These include \code{asyncdial}, \code{autoexit}, and \code{cleanup}.}

\item{tls}{[default NULL] (required for secure TLS connections) \strong{either}
the character path to a file containing the PEM-encoded TLS certificate and
associated private key (may contain additional certificates leading to a
validation chain, with the TLS certificate first), \strong{or} a length 2
character vector comprising [i] the TLS certificate (optionally
certificate chain) and [ii] the associated private key.}

\item{pass}{[default NULL] (required only if the private key supplied to
\code{tls} is encrypted with a password) For security, should be provided
through a function that returns this value, rather than directly.}

\item{rs}{[default NULL] the initial value of .Random.seed. This is set
automatically using L'Ecuyer-CMRG RNG streams generated by the host process
if applicable, and should not be independently supplied.}
}
\value{
Invisible NULL.
}
\description{
Dispatches tasks from a host to daemons for processing, using FIFO
scheduling, queuing tasks as required. Daemon / dispatcher settings are
controlled by \code{\link[=daemons]{daemons()}} and this function should not need to be called
directly.
}
\details{
The network topology is such that a dispatcher acts as a gateway between the
host and daemons, ensuring that tasks received from the host are dispatched
on a FIFO basis for processing. Tasks are queued at the dispatcher to ensure
tasks are only sent to daemons that can begin immediate execution of the
task.
}
