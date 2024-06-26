% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mirai.R
\name{collect_mirai}
\alias{collect_mirai}
\title{mirai (Collect Value)}
\usage{
collect_mirai(x)
}
\arguments{
\item{x}{a \sQuote{mirai} object, or list of \sQuote{mirai} objects.}
}
\value{
An object (the return value of the \sQuote{mirai}), or a list of such
    objects (the same length as \sQuote{x}, preserving names).
}
\description{
\code{collect_mirai} waits for the \sQuote{mirai} to resolve if still in
    progress, and returns its value directly. It is a more efifcient version
    of and equivalent to \code{call_mirai(x)$data}.
}
\details{
This function will wait for the asynchronous operation(s) to
    complete if still in progress (blocking), and is not interruptible.

    \code{x[]} may be used to wait for and return the value of a mirai
    \code{x}, and is the user-interruptible counterpart to
    \code{collect_mirai(x)}.
}
\section{Alternatively}{


    The value of a \sQuote{mirai} may be accessed at any time at
    \code{$data}, and if yet to resolve, an \sQuote{unresolved} logical NA
    will be returned instead.

    Using \code{\link{unresolved}} on a \sQuote{mirai} returns TRUE only if
    it has yet to resolve and FALSE otherwise. This is suitable for use in
    control flow statements such as \code{while} or \code{if}.
}

\section{Errors}{


    If an error occurs in evaluation, the error message is returned as a
    character string of class \sQuote{miraiError} and \sQuote{errorValue}
    (the stack trace is available at \code{$stack.trace} on the error
    object). \code{\link{is_mirai_error}} may be used to test for this.

    If a daemon crashes or terminates unexpectedly during evaluation, an
    \sQuote{errorValue} 19 (Connection reset) is returned (when not using
    dispatcher or using dispatcher with \code{retry = FALSE}). Otherwise,
    using dispatcher with \code{retry = TRUE}, the mirai will remain
    unresolved and is automatically re-tried on the next daemon to connect to
    the particular instance. To cancel the task instead, use
    \code{saisei(force = TRUE)} (see \code{\link{saisei}}).

    \code{\link{is_error_value}} tests for all error conditions including
    \sQuote{mirai} errors, interrupts, and timeouts.
}

\examples{
if (interactive()) {
# Only run examples in interactive R sessions

# using collect_mirai()
df1 <- data.frame(a = 1, b = 2)
df2 <- data.frame(a = 3, b = 1)
m <- mirai(as.matrix(rbind(df1, df2)), df1 = df1, df2 = df2, .timeout = 1000)
collect_mirai(m)

# using x[]
m[]

}

}
