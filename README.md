# vagrant syncer

A Vagrant synced folder plugin that is an optimized implementation of [Vagrant rsync(-auto)](https://github.com/mitchellh/vagrant/tree/b721eb62cfbfa93895d0d4cf019436ab6b1df05d/plugins/synced_folders/rsync), based heavily on [vagrant-gatling-rsync](https://github.com/smerrill/vagrant-gatling-rsync)'s great listener implementations for watching large hierarchies.

Vagrant syncer forks [Vagrant's RsyncHelper](https://github.com/mitchellh/vagrant/blob/b721eb62cfbfa93895d0d4cf019436ab6b1df05d/plugins/synced_folders/rsync/helper.rb)
to make it (c)leaner, instead of using the class like [vagrant-gatling-rsync](https://github.com/smerrill/vagrant-gatling-rsync) does.

If the optimizations seem to work in heavy use, I'll see if (some of) them
can be merged to Vagrant core and be submitted as pull requests to
[the official Vagrant repo](https://github.com/mitchellh/vagrant).


## Installation

    vagrant plugin install vagrant-syncer


## Configuration

All the [rsync synced folder settings](https://docs.vagrantup.com/v2/synced-folders/rsync.html) are supported.
They also have the same default values.

See [the example Vagrantfile](https://github.com/asyrjasalo/vagrant-syncer/blob/master/example/Vagrantfile)
for additional plugin specific ```config.syncer``` settings and their default values.


## Usage

    vagrant syncer

See and try out [the example](https://github.com/asyrjasalo/vagrant-syncer/tree/master/example).

## Improvements over rsync(-auto)

- The plugin uses its own optimized rsync implementation, with most of the rsync command argument constructing already handled in the class initializer and not sync-time
- Uses [rb-fsevent](https://github.com/thibaudgg/rb-fsevent) and [rb-inotify](https://github.com/nex3/rb-inotify) gems underneath for performance on OS X and GNU/Linux, respectively, instead of using OS independent Listen. On other operating systems, it falls back to Listen though for now.
- Allow defining additional SSH arguments to rsync in Vagrantfile using ```config.syncer.ssh_args```
- Start watching changes after machine vagrant up/reload/resume, if ```config.syncer.run_on_startup``` set to ```true``` in Vagrantfile


## Development

Clone this repository and install Ruby 2.2.3, using e.g. [rbenv](https://github.com/sstephenson/rbenv).

    cd vagrant-syncer
    rbenv install $(cat .ruby-version)
    gem install bundler -v1.10.5
    bundle install

Then use it with:

    bundle exec vagrant syncer

Or outside the bundle:

    ./build_and_install.sh
    vagrant syncer


## Credits

[vagrant-syncer](https://github.com/asyrjasalo/vagrant-syncer) is written by Anssi Syrjäsalo (@asyrjasalo).

Thanks to [Steven Merrill's](https://github.com/smerrill) (@stevenmerrill) [vagrant-gatling-rsync](https://github.com/smerrill/vagrant-gatling-rsync)
for [the listener implementations](https://github.com/smerrill/vagrant-gatling-rsync/tree/master/lib/vagrant-gatling-rsync/listen) to tap into [rb-fsevent](https://github.com/thibaudgg/rb-fsevent) (OS X)
and [rb-inotify](https://github.com/nex3/rb-inotify) (GNU/Linux) for non-resource hog watching of hierarchies with 10,000-100,000 files.

Respects to Hashicorp for [Vagrant](https://github.com/mitchellh/vagrant), even though its
future will likely be overshadowed by [Otto](https://github.com/hashicorp/otto).
