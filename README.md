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

All the [rsync synced folder settings](https://docs.vagrantup.com/v2/synced-folders/rsync.html)
are supported. They also have the same default values.

See [the example Vagrantfile](https://github.com/asyrjasalo/vagrant-syncer/blob/master/example/Vagrantfile)
for additional plugin specific ```config.syncer``` settings and their default values.


## Usage

    vagrant syncer

## Improvements over rsync(-auto)

- The plugin has leaner rsync implementation with most of the rsync command
  argument constructing already handled in the class initializer and not sync-time
- Uses [rb-fsevent](https://github.com/thibaudgg/rb-fsevent) and
  [rb-inotify](https://github.com/nex3/rb-inotify) gems underneath for
  performance on OS X and GNU/Linux respectively, instead of using Listen.
  On Windows, Listen is used though as using wdm still needs some testing.
- Allow defining additional SSH arguments to rsync in Vagrantfile using
  ```config.syncer.ssh_args```. This can be used for e.g. disabling SSH
  compression to lower CPU overhead.
- Runs ```vagrant syncer``` to start watching changes after vagrant up, reload
  and resume, if ```config.syncer.run_on_startup``` set to ```true```
  in Vagrantfile
- Vagrant's implementation assumes that the primary group of the SSH user
  has the same name as the user, if rsync option ```group``` is not explicitly
  defined. This plugin queries the user's real primary group from the guest.
- Hooking Vagrant's ```:rsync_pre``` is removed, as this unnecessarily runs mkdir
  to create the target directory, which rsync command creates sync-time anyway.


## Development

Fork this repository, clone it and install Ruby 2.2.3, using e.g. [rbenv](https://github.com/sstephenson/rbenv):

    cd vagrant-syncer
    rbenv install $(cat .ruby-version)
    gem install bundler -v1.10.5
    bundle install

Then use it with:

    bundle exec vagrant syncer

Or outside the bundle:

    ./build_and_install.sh
    vagrant syncer

I'll kindly take pull requests as well.

## Credits

[vagrant-syncer](https://github.com/asyrjasalo/vagrant-syncer) was originally put together by Anssi Syrjäsalo.

Thanks to [Steven Merrill's](https://github.com/smerrill) (@stevenmerrill) [vagrant-gatling-rsync](https://github.com/smerrill/vagrant-gatling-rsync)
for [the listener implementations](https://github.com/smerrill/vagrant-gatling-rsync/tree/master/lib/vagrant-gatling-rsync/listen) and the original idea to tap into [rb-fsevent](https://github.com/thibaudgg/rb-fsevent) (OS X)
and [rb-inotify](https://github.com/nex3/rb-inotify) (GNU/Linux) for non-CPU hog watching of hierarchies with 10,000-100,000 files.

And to [Hashicorp](https://github.com/hashicorp) for [Vagrant](https://github.com/mitchellh/vagrant), even though its
future will likely be overshadowed by [Otto](https://github.com/hashicorp/otto).
