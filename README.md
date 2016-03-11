# vagrant syncer

  This Vagrant plugin optimizes to the following Vagrant commands to not
  be that CPU hog with large file hierachies:

    vagrant rsync
    vagrant rsync-auto

  All the [rsync synced folder settings](https://docs.vagrantup.com/v2/synced-folders/rsync.html)
  are supported. They also have the same default values for backwards compatibility.


## Installation

    vagrant plugin install vagrant-syncer


## Updating

    vagrant plugin update vagrant-syncer


## Configuration

See [the example Vagrantfile](https://github.com/asyrjasalo/vagrant-syncer/blob/master/example/Vagrantfile)
for additional plugin specific ```config.syncer``` settings and their default
values.


## Changes to the Vagrant's rsync and rsync-auto

- The plugin has leaner rsync implementation with most of the rsync command
  argument constructing already handled in the class initializer and not
  sync-time (in the sync loop).
- Uses [rb-fsevent](https://github.com/thibaudgg/rb-fsevent) and
  [rb-inotify](https://github.com/nex3/rb-inotify) gems underneath for
  performance on OS X and GNU/Linux respectively, instead of using Listen.
  On Windows, Listen is used though as using plain wdm gem requires some tests.
- Allow defining additional SSH arguments to rsync in Vagrantfile using
  ```config.syncer.ssh_args```. Use this for e.g. disabling SSH compression to
  lower CPU overhead.
- Runs ```vagrant rsync-auto``` to start watching changes after vagrant up,
  reload and resume, if ```config.syncer.run_on_startup``` set to ```true```
  in Vagrantfile.
- Vagrant's implementation assumes that the primary group of the SSH user
  has the same name as the user, if rsync option ```group``` is not explicitly
  defined. This plugin queries the user's real primary group from the guest.
- Hooking Vagrant's ```:rsync_pre``` is removed, as this unnecessarily runs
  mkdir to create the target directory, which rsync command creates sync-time
  anyway.
- On Windows, expect relative paths, instead of Cygwin style, as Cygwin shall
  not be a requirement.
- ControlPath settings are not in the default SSH arguments on Windows,
  as they fail on
  [Vagrant 1.8.0 and 1.8.1](https://github.com/mitchellh/vagrant/issues/7046).
- Hide "permanently added to the known hosts" messages from rsync stderr output.
- The rsync stdout outputs are all single line by default, and colored.


## Development

Fork this repository, clone it and install Ruby 2.2.3, using e.g.
[rbenv](https://github.com/sstephenson/rbenv):

    cd vagrant-syncer
    rbenv install $(cat .ruby-version)
    gem install bundler -v1.10.5
    bundle install

Then use it with:

    bundle exec vagrant rsync-auto

Or outside the bundle:

    ./build_and_install.sh
    vagrant rsync-auto

Also, I kindly take pull requests.

## Credits

[vagrant-syncer](https://github.com/asyrjasalo/vagrant-syncer) was originally
put together by Anssi Syrjäsalo.

Thanks to [Steven Merrill's](https://github.com/smerrill) (@stevenmerrill)
[vagrant-gatling-rsync](https://github.com/smerrill/vagrant-gatling-rsync) for
[the listener implementations](https://github.com/smerrill/vagrant-gatling-rsync/tree/master/lib/vagrant-gatling-rsync/listen) and the original idea to tap into [rb-fsevent](https://github.com/thibaudgg/rb-fsevent)
(OS X) and [rb-inotify](https://github.com/nex3/rb-inotify) (GNU/Linux) for
non-CPU hog watching of hierarchies with 10,000-100,000 files.

And to [Hashicorp](https://github.com/hashicorp) for
[Vagrant](https://github.com/mitchellh/vagrant), even though its future will
likely be overshadowed by [Otto](https://github.com/hashicorp/otto).
