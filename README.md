# vagrant syncer

A Vagrant plugin that is an optimized implentation of Vagrant rsync(-auto),
based heavily on [vagrant-gatling-rsync](https://github.com/smerrill/vagrant-gatling-rsync)
and its efficient listener implementations for watching large hierarchies.

Parts of the code will likely be kindly submitted to the
[Vagrant core](https://github.com/mitchellh/vagrant) as
pull requests later, if they seem to function in heavy usage.


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
