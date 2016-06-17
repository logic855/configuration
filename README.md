Managing Configuration with *git*, *git2consul*, and *envconsul*
================================================================

This repository describes and demonstrates how to use *Consul* and a set of
open source tools to manage the configuration of any number of hosts
and services. While Consul has a number of features, this particular
purpose applies only its hierarchical, flexible key/value store.


The Goal
-----------

Maintain critical system and application configuration with engineering rigor
and automatically propagate and effectuate changes to any number of servers.


The Solution
------------

Combine *Consul*, *git*, *git2consul*, and *envconsul*.

* Each setting is defined in a text file and all files are maintained in a single *git* repsository.

* git2consul proactively monitors a branch on a *git* repository. On any *commit* to the branch, the
contents of the repository are uploaded into the Consul key-value store. The key of each pair is
derived from pathname of the file (relative to the root of the repo); the value stored at the key is
the content of the file.

* *envconsul* monitors Consul for changes to specific sets of keys. Any change causes *envconsul* to
emit a set of environment variables  (or *envars*, for short), where the name of each envar is the
base name of its key and its value is the content stored at the key.

* *envconsul* (re)starts a service any time one or more envar changes.


Architecture
------------

In the diagram below, all systems are connected to an internal network unreachable from the larger
internet.

![The architecture of the envconsul system][architecture]

The Consul cluster, center, is composed of a number of machines. Consul has many features, but the
prominent one leveraged here is its key-value store. Both git2consul and envconsul utilities act as
clients of the cluster, albeit with different roles: git2consul writes information to Consul and
envconsul reads from the cluster.

The Git server at left has two configuration repositories, A and B. A and B are collections of
folders and subfolders and simple text files, where every file in the repository follows two simple
rules:

The name of the file is the name of a environment variable to be managed. The content of the file is
the value of the environment variable.

For example, say repo A contained a file named mysql_server with one line of content, the string
mysql.mynetwork.com. Per convention, the file yields the functional equivalent of export
MYSQL_SERVER=mysql.mynetwork.com. The filename is uppercased and special characters (if any) are
replaced to yield the variable name. The value of the variable is the content of the file.

Both repositories are monitored by separate servers running git2consul. git2consul watches repos for
changes. It can watch a single branch or many, and can be limited to specific paths within the repo.
At startup and whenever an apt commit appears, git2consul translates the files in the watched
section of the repo to keys and values in Consul.


Benefits
--------

The amalgam of *git*, *git2consul*, and *envconsul* marry the rigor of source control with the
convenience and reliability of automation.

* All changes to configuration are captured in the repository, including the
author and date and time of the change.

* Change can be vetted and approved using common git tools and practices, such as
pull requests, and can be managed via git tags, branches, rollbacks, and releases.

* A change forces a restart. No manual intervention is required.


An Example Strategy
-------------------

Imagine your business is powererd by a large number of services, executing on many hosts divided
among regional datacenters.

Each datacenter is a wholly-contained operation, able to  provide seamless continuity in the event
of failure of other regions.

Each service runs on two or more hosts in each datacenter to boost throughput and availability.
Typical load balancing directs traffic to make efficient use of all resources.

Further, portions of the infrastructure are allocated to  qualification. One or more "staging"
environments mirror entirely the capabilities of production but run advanced versions of services.
Generally, each pre-production environment is independent and  intentionally walled away from the
others.

Conceptually, such infrastructure might be collected as follows:

* **Global**: All hosts under your management.

* **Datacenter**: All hosts within a sole physical location.

* **Application**: Hosts assigned a distinct purpose, such as running a specific microservice or
application.

* **Environment**: Hosts dedicated to a phase of development. Production, staging, test, and development are some example phases.

* **Cluster**: A set of hosts devoted to a distinct purpose in a sole environment.

* **Host**: An individual host.

* **Daemon**: A reachable, networked utility (e.g., a database, a cache, an API) on a specific host.

Global encompasses every host, while daemon narrows to a specific utility on a single host (typically,
a Linux service of some kind, like *sshd* or *mysqld*). Configuration can be applied to
any stratum.


Here are some further assumptions about the strategy:

1. Application and system configuration variables are managed solely via Git. Direct, manual editing
of environment configuration (files on servers) is strictly forbidden.

3. Instead, environment variables for an application (such as Puma and Rails) are generated on
startup and when any commit changes monitored sections of the repo.

4. If an application depends on an environment variable and that variable changes because of a
commit, the application must restart to effectuate the change.

5. An environment variable specific to a version of software must have a version-specific name. For
example, if an application has been converted from Oauth V1.0 to Oauth V2.0, the application might
find the key for the former protocol in OAUTH_V1 and the latter in OAUTH_V2

6. The name of an application-specific environment variable is guaranteed not to collide with one
from another application.

7. Not all configuration options are suitable for this scheme. In general, the system is designed to
manage (relatively) long-lived values. A/B testing is best left to tools such as Optimizely; feature
flags may be better managed using other techniques.


### Modeling the Infrastructure

This repository contains a number of folders: *globals*, *datacenters*, *applications*, *environments*,
*clusters*, *hosts*, and *daemons*, reflecting the conceptual organization of hosts described above.
Here, each folder defines environment variables for a specific stratum.

For example, the *datacenters* folder defines environment variables for all hosts in a
datacenter, while *applications* manages the envars for all servers dedicated to a specific
application.

As before, the *globals* folder is to be least specific, defining envars that apply to every host. Near the
other extreme, *hosts* is very specific used to define envars for a single host. The complete
hierarchy, from least specific (top) to most specific (bottom) is:

* Globals
* Datacenters
* Applications
* Environments
* Clusters
* Hosts
* Daemons

Given such precedence, an environment variable defined in *datacenters* supercedes the same environment
variable defined in *globals*. Similarly, an envar defined in *hosts* would quash the same envar defined
in *clusters*. A simple preeminence rule provides for great customization of configuration.


### Configuration, One Per File

Configuration tends to be long lists of variables and values, often in application-specfic formats. A syntax
error can alter operation significantly or even prevent booting. In this scheme, configuration is simple:

* Each file in the repository defines a single envar.

* The name of the file forms the basis for the name of the environment variable.
Each file name is upper-cased and URL-encoded to yield the final variable name.

* The content of the file is always text and **defines** the variable's value.

For example, a file named ```database_url``` with contents ```mysql.example.com``` ultimately yields the environment variable...

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  DATABASE_URL=mysql.example.com
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Each folder contains zero or more files and zero or more subfolders.


### Managing the Configurations

where each folder contains a collection of one or
more machines to be managed. There is a folder

Each folder contains zero or more environment variable definitions. The name of the file forms the basis for the
name of the environment variable, while the content of the file **defines** the variable's value. Each file name is upper-cased and URL-encoded to yield a variable name.

For example, a file named ```database_url``` with contents ```mysql.example.com``` ultimately yields the environment variable...

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  DATABASE_URL=mysql.example.com
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Multiple files of the same name can exist in separate folders. Thus, each file has a unique pathname.

*git2consul* uploads each file into Consul, using the file's pathname as a unique key and the file's
content as the value. *git2consul* automatically reloads the contents of the repo into Consul on any commit.

*envconsul* scans for keys in Consul in a defined order and converts
each *(key, value)* pair found into an environment variable definition. *envconsul* monitors
Consul and is able to run arbitrary commands on any change.

Combined, *git2consul* and *envconsul* can be used to carefully control
a corpus of environment variables and automatically restart servers when values are altered.


Conceptually, the order in which folders are scanned
determines precedence, with folder contents scanned early having least precedence.


For example, assume files *a/database_url* and *b/database_url* exist, with content ```a.example.com``` and
```b.example.com```, respectively. If folder  *a* is scanned followed by *b*,
the latter file has precedent and *envconsul* yields...

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  DATABASE_URL=b.example.com
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If *b* is scanned before *a*, the result is opposite:

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  DATABASE_URL=a.example.com
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can configure *envconsul* to scan any number of folders in any order to create precedence rules.


The Need for Rolling Restarts
-----------------------------

*envconsul* restarts the service it manages independently and promptly, generally within a few
seconds after a *git* commit is made. (Recall that *git2consul* monitors express branches in the
repository and *envconsul* effectively monitors discrete paths in the repository. Only changes of
interest to envconsul spark a restart.) If *envconsul* manages the same service on a number of hosts
-- as is intended -- a "brownout" is possible: all instances of the service could restart at the
same time, making the service unreachable, albeit for a (very) short time.
However, a brownout is unacceptable. To avoid it, you must implement a "zero-downtime,"
or *rolling,* restart.

A rolling restart kills running server threads (or processes) only when a request is complete.
New threads -- with new code new environment variables, too -- are spawned to process new requests.

Luckily, many modern services support zero-downtime restarts. For example, the *puma* and *unicorn*
application servers for Ruby both provide a rolling restart or phased restart. The *puma*
documentation explains:

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Puma kills workers one-by-one, meaning that at least another worker is still
  available to serve requests, which lead[sic] to zero hanging requests (yay!).
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A *puma* phased restart can be initiated via the ```USR1``` signal. *envconsul* can automatically
send this signal to *puma* upon detection of a change. For example, if the line...

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  kill_signal="SIGUSR1"
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

... appears in the *envconsul* configuration file, the shell command


  ```shell-script
  $ envconsul -config demo.config.hcl rails server
  ```

restarts the Rails application when any monitored path and branch in the repo is modified.

One tip: Do not use the ```pristine = true``` option if your application depends on environment
variables from the system-at-large. ```pristine = true```effectively clears your environment.


How to demonstrate this system
------------------------------

Unless you are instructed otherwise, you may install the prequisites listed in
these instructions either from source code or via your operating
system's package manager, such as *brew* or *apt.*

1.  Install *git*. (Git is required here only to make commits to the sample
    repo. Git need not be installed on servers for this system to function.)

2.  Install *npm*. (Unless specifically instructed otherwise, you can choose to
    install the software listed in these instructions from source or via your
    operating system's package manager, such as *brew* or *apt-get.*)

3.  Install *consul*.

    If you are using *brew* as a package manager, you can install *consul* with:

    ```shell-script
    $ brew cask install consul
    ```

    If you are missing the cask plugin, you can install it with:

    ```shell-script
    $ brew install caskroom/cask/brew-cask
    ```

4.  Install *Go*.

5.  Install *git2consul*.

    ```shell-script
    $ npm install -g git2consul
    ```

6.  Run *consul* in non-daemon mode.

    ```shell-script
    $ consul agent -dev
    ```

    The consul agent produces something like this on start:

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ==> Starting Consul agent...
      ==> Starting Consul agent RPC...
      ==> Consul agent running!
         Node name: 'Colossus.local'
        Datacenter: 'dc1'
            Server: true (bootstrap: false)
       Client Addr: 127.0.0.1 (HTTP: 8500, HTTPS: -1, DNS: 8600, RPC: 8400)
      Cluster Addr: 192.168.0.2 (LAN: 8301, WAN: 8302)
    Gossip encrypt: false, RPC-TLS: false, TLS-Incoming: false
             Atlas: <disabled>
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

7.  Create a directory for your Go code and set the `GOPATH` environment
    variable to point to that directory. For example, if you chose *\~/go* for
    your work, you could run…

    ```shell-script
    $ mkdir ~/go; export GOPATH=~/go
    ```

8.  Copy the *envconsul* repository into your Go environment.

    ```shell-script
    $ go get github.com/hashicorp/envconsul
    ```

9.  Change to the source directory created by the previous step.

    ```shell-script
    $ cd $GOPATH/src/github.com/hashicorp/envconsul
    ```

10. Build the *envconsul* binary with…

    ```shell-script
    $ make
    ```

    The build of the code should produce something akin to this:

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Generating...
  ==> Running tests...
  ok   github.com/hashicorp/envconsul 2.276s
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

11.  Clone this repository anywhere in your file system.

  ```shell-script
  $ cd /tmp
  $ git clone git@github.com:martinstreicher/configuration.git
  ```

12.  Change into the new directory created by cloning. Launch *git2consul*.

  ```shell-script
  $ cd ./configuration
  $ git2consul --config-file git2consul.config.json
  ```

  The utility emits some helpful diagnostics on startup. (Whitespace has been added to improve readability.)

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  {"name":"git2consul","hostname":"Colossus.local","pid":6358,"level":30,
    "msg":"Adding git2consul.config.json to KV git2consul/config as: \n{\n  \"version\": \"1.0\",\n  \"repos\": [{\n    \"name\": \"configuration\",\n    \"url\": \"https://github.com/martinstreicher/configuration.git\",\n    \"branches\": [\"master\"],\n    \"hooks\": [{\n      \"type\": \"polling\",\n      \"interval\": \"1\"\n    }]\n  }]\n}\n","time":"2016-06-28T14:26:02.204Z","v":0}

  {"name":"git2consul","hostname":"Colossus.local","pid":6358,"level":30,
    "msg":"git2consul is running","time":"2016-06-28T14:26:02.384Z","v":0}

  {"name":"git2consul","hostname":"Colossus.local","pid":6358,"level":30,
    "msg":"Initting repo configuration","time":"2016-06-28T14:26:02.387Z","v":0}

  {"name":"git2consul","hostname":"Colossus.local","pid":6358,"level":30,
    "msg":"Initting branch /var/folders/55/p5mwykxx64l30jy7lp49bfw00000gn/T/configuration /var/folders/55/p5mwykxx64l30jy7lp49bfw00000gn/T/configuration/master","time":"2016-06-28T14:26:02.387Z","v":0}

  {"name":"git2consul","hostname":"Colossus.local","pid":6358,"level":40,
    "msg":"Purging branch cache /var/folders/55/p5mwykxx64l30jy7lp49bfw00000gn/T/configuration/master for
    branch master in repo configuration","time":"2016-06-28T14:26:02.388Z","v":0}

  {"name":"git2consul","hostname":"Colossus.local","pid":6358,"level":30,
    "msg":"Initialized branch master from configuration","time":"2016-06-28T14:26:04.593Z","v":0}

  {"name":"git2consul","hostname":"Colossus.local","pid":6358,"level":30,
    "msg":"Loaded repo configuration","time":"2016-06-28T14:26:04.594Z","v":0}
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Here, *git2consul* loads its own configuration into the Consul key-value store. With the configuration loaded,
  you can restart *git2consul* without the ```--config-file git2consul.config.json``` argument. The rest of the information
  shows that the utility has read and loaded the contents of the repo into the store.

13.  Finally, to see the contents of the store, run *envconsul*.

  ```shell-script
  $ envconsul -config thor.envconsul.config.hcl env
  ```

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ATL_IMPORTANT_HOST=datacenters/atl/important_host
  DATABASE_HOST=localhost
  ENVIRONMENT_HOST=environemnts/qa/environment_host
  GLOBAL_SETTING=globals/global_setting
  IMPORTANT_HOST=hosts/thor/important_host
  LAX_IMPORTANT_HOST=datacenters/lax/important_host
  QA_ENVIRONMENT_HOST=environemnts/qa/environment_host
  THOR_IMPORTANT_HOST=hosts/thor/important_host
  V1_IMPORTANT_HOST=applications/ag/v1/important_host
  V2_IMPORTANT_HOST=applications/ag/v2/important_host
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  All of the values used in this demonstration are path names. Specifically,
  each value indicates where it is defined in the repo. For example, the content of
  file [*globals/global_setting*](https://github.com/martinstreicher/configuration/blob/master/globals/global_setting)
  is...

  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  globals/global_setting
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  A value can be any string usable in an environment variable; the values in this example were
  intentionally chosen to help clarify how to define, configure, and override environment variables
  using Git and envconsul.


References (in alphabetical order)
----------------------------------

-   [a​pt](https://en.wikipedia.org/wiki/Advanced_Packaging_Tool)

-   [brew](http://brew.sh)

-   [Consul](https://www.consul.io)

-   [envconsul](https://github.com/hashicorp/envconsul.git)

-   [git](https://git-scm.com)

-   [git2consul](https://github.com/Cimpress-MCP/git2consul)

-   [Github](https://github.com)

-   [The go Programming Language](https://golang.org/doc/install)


[architecture]: architecture.png
