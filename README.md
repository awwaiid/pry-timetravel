# pry-timetravel

Time travel! For your REPL!

    > x = 5
    5
    > snap
    > x = 10
    10
    > back
    > x
    5

This is an attempt to package the proof of concept. API WILL CHANGE!

## How it works

The 'snap' command causes a fork, and the child is sent a SIGSTOP to freeze the
process. The parent continues on. Later when you do 'back' the saved child is
sent SIGCONT and the current process is sent a SIGSTOP. Ultimately you can have
a whole pool of frozen snapshots and can resume any of them.

In theory copy-on-write semantics makes this a tollerable thing to do :)

There are a few more details, but that is the important bit.

WARNING: Time travel may cause zombies.

## KNOWN ISSUES

### General

* If you close a connection, like to a DB, it is closed for all snapshots

### Redis fork detection

Redis checks to see if you forked and yells at you about needing to reconnect.
Reasonably so, as it is a crazy idea to use the same connection in forked
children! But we are doing crazy things. In 3.1.0 the gem will auto-reconnect,
or you can pass inherit_socket to the connection to stop that. Or you can do
this to bypass safety measures:

    class Redis
      class Client
        def ensure_connected
          yield
        end
      end
    end

## Similar Technology

* [Time Travel Python Debugger](https://github.com/TomOnTime/timetravelpdb)
* [Elm's Time Traveling Debugger](http://debug.elm-lang.org/)
* [OCaml Time Travel](http://caml.inria.fr/pub/docs/manual-ocaml-4.00/manual030.html#htoc195)
* [Chronon (java - proprietary)](http://chrononsystems.com/)

## Meta

Released under the MIT license, see LICENSE.MIT for details. License is
negotiable. Contributions and bug-reports are welcome!

