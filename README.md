# marknl/gobyte-core

A gobyte-core docker image.

[![marknl/gobyte-core][docker-pulls-image]][docker-hub-url] [![marknl/gobyte-core][docker-stars-image]][docker-hub-url] [![marknl/docker-gobyte-core][travis-build-image]][travis-build-url]

## Tags
- `0.12.2.4`, `0.12`, `latest` ([0.12/Dockerfile](https://github.com/marknl/docker-gobyte-core/blob/master/0.12/Dockerfile))
- `0.12.2.4-ubuntu`, `0.12-ubuntu`` ([0.12/ubuntu/Dockerfile](https://github.com/marknl/docker-gobyte-core/blob/master/0.12/ubuntu/Dockerfile))

## What is GoByte Core?

GoByte Core is a reference client that implements the GoByte protocol for remote procedure call (RPC) use. It is also the second GoByte client in the network's history. Learn more about GoByte Core [here](https://gobyte.network).

## Usage

### How to use this image

This image contains the main binaries from the GoByte Core project - `gobyted`, `gobyte-cli` and `gobyte-tx`. It behaves like a binary, so you can pass any arguments to the image and they will be forwarded to the `gobyted` binary:

```sh
❯ docker run --rm -it marknl/gobyte-core \
  -printtoconsole \
  -rpcallowip=172.17.0.0/16 \
  -maxconnections=12
```

By default, `gobyted` will run as user `gobyte` for security reasons and with its default data directory (`~/.gobytecore`). If you'd like to customize where `gobyte-core` stores its data, you must use the `GOBYTE_DATA` environment variable. The directory will be automatically created with the correct permissions for the `gobyte` user and `gobyte-core` automatically configured to use it.

```sh
❯ docker run --env GOBYTE_DATA=/some/other/folder --rm -it marknl/gobyte-core \
  -printtoconsole
```

You can also mount a directory it in a volume under `/home/gobyte/.gobytecore` in case you want to access it on the host:

```sh
❯ docker run -v ${PWD}/data:/home/gobyte/.gobytecore -rm --it marknl/gobyte-core \
  -printtoconsole
```

You can optionally create a service using `docker-compose`:

```yml
gobyte-core:
  image: marknl/gobyte-core
  command:
    -printtoconsole
```

### Using RPC to interact with the daemon

There are two communications methods to interact with a running GoByte Core daemon.

The first one is using a cookie-based local authentication. It doesn't require any special authentication information as running a process locally under the same user that was used to launch the GoByte Core daemon allows it to read the cookie file previously generated by the daemon for clients. The downside of this method is that it requires local machine access.

The second option is making a remote procedure call using a user name and password combination. This has the advantage of not requiring local machine access, but in order to keep your credentials safe you should use the newer `rpcauth` authentication mechanism instead of the older rpcuser and rpcpassword combination.

#### Using cookie-based local authentication

Start by launching the GoByte Core daemon:

```sh
❯ docker run --rm --name gobyte-server -it marknl/gobyte-core \
  -printtoconsole
```

Then, inside the running `gobyte-server` container, locally execute the query to the daemon using `gobyte-cli` via `docker exec`:

```sh
❯ docker exec --user gobyte gobyte-server gobyte-cli getmininginfo

{
  "blocks": 280130,
  "currentblocksize": 0,
  "currentblocktx": 0,
  "difficulty": 64.21090099089479,
  "errors": "",
  "genproclimit": 1,
  "networkhashps": 2706700426.603354,
  "pooledtx": 0,
  "testnet": false,
  "chain": "main",
  "generate": false
}
```

In the background, `gobyte-cli` read the information automatically from `/home/gobyte/.gobytecore/.cookie`.

#### Using rpcuser and rpcpassword for remote authentication

Start by launching a GoByte daemon with:

```sh
> docker run --rm --name gobyte-server -it marknl/gobyte \
  -printtoconsole \
  -rpcallowip=172.17.0.0/16 \
  -rpcuser=<username> \
  -rpcpassword=<password>
```

You can now connect via `gobyte-cli`. You will still have to define a user name and password when connecting to the GoByte Core RPC server.

```sh
❯ docker run -it --link gobyte-server --rm marknl/gobyte-core \
  gobyte-cli \
  -rpcconnect=gobyte-server \
  -rpcuser=<username>\
  -rpcpassword=<password> \
  getbalance

0.00000000
```

#### Using rpcauth for remote authentication

Before setting up remote authentication, you will need to generate the `rpcauth` parameter that will hold the credentials for the GoByte Core daemon. You can either do this yourself by constructing the line with the format `<user>:<salt>$<hash>` or use the official `rpcauth.py` script to generate this line for you, including a random password that is printed to the console.

```sh
❯ curl -sSL https://raw.githubusercontent.com/bitcoin/bitcoin/master/share/rpcauth/rpcauth.py | python - <username> <password>

String to be appended to bitcoin.conf:
rpcauth=<username>:54e8482e256d24dc218f17141250372c$324ff557c8c51a730c86d1fbaa1525d9a211e6ede12f9b9a7c32ea465d4a14bf
Your password:
<password>
```

Note that for each run, even if the user name remains the same, the output will be always different as a new salt is used to create a hash for the password.

Now that you have your credentials, you need to start the GoByte Core daemon with the `-rpcauth` option. Alternatively, you could append the line to a `gobyte.conf` file and mount it on the container.

Let's opt for the Docker way:

```sh
❯ docker run --rm --name gobyte-server -it marknl/gobyte-core \
  -printtoconsole \
  -rpcallowip=172.17.0.0/16 \
  -rpcauth='<username>:54e8482e256d24dc218f17141250372c$324ff557c8c51a730c86d1fbaa1525d9a211e6ede12f9b9a7c32ea465d4a14bf'
```

Two important notes:

1. Some shells require escaping the rpcauth line (e.g. zsh), as shown above.
2. It is now perfectly fine to pass the rpcauth line as a command line argument. Unlike `-rpcpassword`, the content is hashed so even if the arguments would be exposed, they would not allow the attacker to get the actual password.

You can now connect via `gobyte-cli`. You will still have to define a user name and password when connecting to the GoByte Core RPC server.

To avoid any confusion about whether or not a remote call is being made, let's spin up another container to execute `gobyte-cli` and connect it via the Docker network using the password generated above:

```sh
❯ docker run -it --link gobyte-server --rm marknl/gobyte-core \
  gobyte-cli \
  -rpcconnect=gobyte-server \
  -rpcuser=<username>\
  -rpcpassword=<password> \
  getbalance

0.00000000
```

### Exposing Ports

Depending on the network (mode) the GoByte Core daemon is running as well as the chosen runtime flags, several default ports may be available for mapping.

Ports can be exposed by mapping all of the available ones (using `-P` and based on what `EXPOSE` documents) or individually by adding `-p`. This mode allows assigning a dynamic port on the host (`-p <port>`) or assigning a fixed port `-p <hostPort>:<containerPort>`.

Example for running a node with mapping JSON-RPC/REST (12454) and P2P (12455) ports:

```sh
docker run --rm -it \
  -p 12454:12454 \
  -p 12455:12455 \
  marknl/gobyte-core \
  -printtoconsole \
  -testnet=1 \
  -rpcallowip=172.17.0.0/16 \
  -rpcauth='<username>:54e8482e256d24dc218f17141250372c$324ff557c8c51a730c86d1fbaa1525d9a211e6ede12f9b9a7c32ea465d4a14bf'
```

To test that mapping worked, you can send a JSON-RPC curl request to the host port:

```
curl --data-binary '{"jsonrpc":"1.0","id":"1","method":"getnetworkinfo","params":[]}' http://<username>:<password>@127.0.0.1:12454/
```

## Masternode
See [masternode.md](https://github.com/marknl/docker-gobyte-core/blob/master/docs/masternode.md) for instructions on how to run this docker image as a masternode.

## Docker

This image is officially supported on Docker version 18.06, with support for older versions provided on a best-effort basis.

## License

[License information](https://github.com/gobytecoin/gobyte/blob/master/COPYING) for the software contained in this image.

[License information](https://github.com/marknl/docker-gobyte-core/blob/master/LICENSE) for the [marknl/docker-gobyte-core][docker-hub-url] docker project.

[docker-hub-url]: https://hub.docker.com/r/marknl/gobyte-core
[docker-pulls-image]: https://img.shields.io/docker/pulls/marknl/gobyte-core.svg?style=flat-square
[docker-stars-image]: https://img.shields.io/docker/stars/marknl/gobyte-core.svg?style=flat-square
[travis-build-url]: https://travis-ci.org/marknl/docker-gobyte-core
[travis-build-image]: https://img.shields.io/travis/marknl/docker-gobyte-core.svg
