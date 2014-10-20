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

## Meta

Released under the MIT license, see LICENSE.MIT for details. License is
negotiable. Contributions and bug-reports are welcome!

