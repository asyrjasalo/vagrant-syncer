#!/usr/bin/env bash

bundle exec rake build && vagrant plugin install pkg/vagrant-syncer-*.gem
