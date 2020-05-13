![Rappel Logo](apps/rappel_web/assets/static/images/rappel_logo.png)

# Howdy

THIS PROJECT IS SUPER-EARLY, NOT SO MUCH ALPHA AS BEFORE THE DAWN OF WRITING, SOME INCHOATE SYMBOLS SCRAWLED WITH A HALF-BURNT STICK ON A CAVE WALL.

If you want to help develop it, dive in.

## How We Develop

Development is done inside a docker container.

The docker container mounts the local file system so code can be edited on your normal machine.

Ports are punched out from the firewall so that `rappel` can be started in a browser running from your normal host.

Scripts are provided that shell you into the running docker instance. 

The docker container is even jiggered so you can start X-Windows programmes and pop them out (though this is not really necessary).

DEVELOPMENT PROTOCOLS ARE NOT YET DEFINED:

* feature specification
* testing and CI (Continuous Integration)
* branches to push to
* pull requests and reviews
* etc, et bloody cetera

THESE ARE NEXT ON THE AGENDA

## Installation

You need to have `docker` installed on your machine.

https://docs.docker.com/get-docker/

You need to clone this repo and the `Pometo` repo side by side in your file system

`git clone git@github.com:gordonguthrie/pometo.git`
`git clone git@github.com:gordonguthrie/rappel.git`

Once the source code is available we bring up the `rappel` docker container

```
cd $GITROOT/rappel
docker-compose build
docker-compose up
```

This will leave docker running in that terminal. Switch to another terminal:

```
cd $GITROOT/rappel/scripts
sh start_rappel.sh
```

This will log you into the docker instance.

The `rappel` app is in the directory `/rappel` and `pometo` is in `/pometo`

To start `rappel` you should run the following commands inside the docker container:

```
cd /rappel
iex -S mix phx.server
```

And then open a browser with `http://localhost:4000`

`Elixir/Phoenix` has a good working/hot-reoadling cycle when developing the main `Elixir` app, not so good for changing dependencies on the fly.

The typical dev cycle is:

* edit code in the `Pometo` repository
* crash out of `iex` and the `rappel` app back to the command line
* restart `rappel` in `iex`

`Pometo` is all about the interopability - so developing it is currently in two languages (`Erlang` and `Elixir`) and depending on how the runtime pans out, potentially in three with `LFE` (or `Lisp Flavoured Erlang`) being the current compiler target of choice.

Typically compilers produce an `Abstract Syntax Tree` or `AST` as an output and oftentimes this is a `YASL` (`Yet Another Shitty Lisp`).

It makes sense to have a `LISP`-`LISP` for the `AST` and the proposed format is an `Erlang` data structure code-named `Liffey` which has the property that if you `to_string()` it, then it becomes `LFE` source code.