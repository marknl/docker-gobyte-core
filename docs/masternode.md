# Masternode

This docker image can be used to run a masternode. The requirement of a masternode is that has has to be directly connected to the Internet so it can communicate with other nodes in the network.

This document describes how to run a masternode (or multiple nodes) from within a single Docker host using cookie-based local authentication. For details on authentication methods, check the main [README](https://github.com/marknl/docker-gobyte-core/blob/master/README.md).

## Setup

It is assumed you already have locked the collateral, have one or more masternode private keys (`MASTERPRIVKEY`) and configured the `masternode.conf` file in your wallet, ready to start the masternode.

### Networking

Other nodes need to be able to talk to your masternode. Therefor the docker host should have a external IP address, or you should setup NAT to reach the internal IP address of the docker host. (The latter is outside of the scope of this document). Each node needs a different IP address, you cannot share these since you may only use a port once per IP address, this means you need to add a unique IP address for each node to the docker host.

### Single node

Launch a GoByte Core daemon with:

```sh
> docker run --restart=always -d -p 12455:12455 --name gobytemn marknl/gobyte-core -printtoconsole -masternode=1 -maxconnections=16 -masternodeprivkey=MASTERPRIVKEY
```

This will start a docker container from the image `marknl/gobyte-core`, map port `12455`, name it  `gobytemn` and run it as a daemon.
`--restart=always` will make sure that the container is restarted each time the server is rebooted, or docker is restarted.

The configuration options the GoByte Core daemon received are:
- printtoconsole
- masternode=1
- max connections=16
- masternodeprivkey=MASTRPRIVKEY

You may add more options if needed, see `docker run --rm -it marknl/gobyte-core --help` for all possible parameters.

Last thing to do is issue a `start-alias` from within the wallet that contains the collateral.

### Multi node

As an example, two masternodes will be run on different IP addresses, 192.168.10.1 and 192.168.10.2. (In a real life scenario, these IP addresses will be public IP addresses, active on the docker host.)

Start the first GoByte Core daemon with:

```sh
> docker run --restart=always -d -p 192.168.10.1:12455:12455 --name gobytemn01 marknl/gobyte-core -printtoconsole -masternode=1 -maxconnections=16 -masternodeprivkey=MASTERPRIVKEY01
```

```sh
> docker run --restart=always -d -p 192.168.10.2:12455:12455 --name gobytemn02 marknl/gobyte-core -printtoconsole -masternode=1 -maxconnections=16 -masternodeprivkey=MASTERPRIVKEY02
```

Now issue a `start-all` from within the wallet that contains the collateral.
