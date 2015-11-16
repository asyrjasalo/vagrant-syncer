# vagrant syncer

A Vagrant plugin that is an optimized implentation of Vagrant rsync(-auto),
based heavily on [vagrant-gatling-rsync](https://github.com/smerrill/vagrant-gatling-rsync)
and its great listener implementations for watching large hierarchies.

Vagrant syncer implements its own rsync loop, heavily forked from
[Vagrant's RsyncHelper](https://github.com/mitchellh/vagrant/blob/b721eb62cfbfa93895d0d4cf019436ab6b1df05d/plugins/synced_folders/rsync/helper.rb),
instead of using the class, like [vagrant-gatling-rsync](https://github.com/smerrill/vagrant-gatling-rsync) does.

All the Vagrant rsync synced folder settings are supported by this plugin.
They also have the same default values.

It the optimizations seem to work in heavy use, I'll see if (some of) them
can be merged to Vagrant core and be submitted as pull requests to the
[official Vagrant repo](https://github.com/mitchellh/vagrant).


## Building

Clone this repository and install Ruby 2.2.3, using e.g. rbenv.

```bash
cd vagrant-syncer
rbenv install $(cat .ruby-version)
gem install bundler -v1.10.5
bundle install
./build_and_install.sh
```

## Usage

```bash
vagrant syncer
```

## 1.0 TODO

- commit a proper README.md
- add Vagrant Specs and/or RF SSHLibrary tests
- `vagrant plugin install vagrant-syncer`

## 1.1 TODO

- test Listen (WDM) and direct wdm.gem implementation on Windows (7, 8.1, 10)
- considerations for additional backends than rsync?

## Later TODO

- test Listen (kqueue) on FreeBSD/NetBSD
- maybe even on Solaris and SmartOS?
