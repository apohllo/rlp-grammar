#!/bin/env ruby
# encoding: utf-8

require 'bundler/setup'
require 'rlp/grammar'

$ROD_DEBUG = true
Rlp::Grammar::Client.instance.migrate_database("../rlp-corpus/data/rlp")
