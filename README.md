# vagrant syncer

A Vagrant plugin that is an optimized implementation of [Vagrant rsync(-auto)](https://github.com/mitchellh/vagrant/tree/b721eb62cfbfa93895d0d4cf019436ab6b1df05d/plugins/synced_folders/rsync),
based heavily on [vagrant-gatling-rsync](https://github.com/smerrill/vagrant-gatling-rsync)'s
great listener implementations for watching large hierarchies.

All the [rsync synced folder settings](https://docs.vagrantup.com/v2/synced-folders/rsync.html) are supported.
They also have the same default values.

Vagrant syncer forks [Vagrant's RsyncHelper](https://github.com/mitchellh/vagrant/blob/b721eb62cfbfa93895d0d4cf019436ab6b1df05d/plugins/synced_folders/rsync/helper.rb)
to make it (c)leaner, instead of using the class like [vagrant-gatling-rsync](https://github.com/smerrill/vagrant-gatling-rsync) does.

If the optimizations seem to work in heavy use, I'll see if (some of) them
can be merged to Vagrant core and be submitted as pull requests to
[the official Vagrant repo](https://github.com/mitchellh/vagrant).


## Developing

Clone this repository and install Ruby 2.2.3, using e.g. [rbenv](https://github.com/sstephenson/rbenv).
```
cd vagrant-syncer
rbenv install $(cat .ruby-version)
gem install bundler -v1.10.5
bundle install
```

Then use it with:
```
bundle exec vagrant syncer
```

Or outside the bundle:
```
./build_and_install.sh
vagrant syncer
```


## Usage

```
vagrant syncer
```
