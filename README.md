radiodan_example
================

Example application using the radiodan gem

## Getting started

- Download and install [Vagrant](http://downloads.vagrantup.com/)
- `$ vagrant up`
- Shell into the virtual machine `$ vagrant ssh`
- Change to the application directory, mounted as `$ cd /vagrant`
- Install the dependencies for the app `$ bundle install`
- Start the radio application `$ bin/start`

The radio should start playing. You can invoke "panic mode" by creating (or touching) a file named `panic` in the `tmp` directory e.g. `$ touch tmp/panic`. You should hear a different radio station play for 5 seconds.
