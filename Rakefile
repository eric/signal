# -*- ruby -*-

$: << File.join(File.expand_path(File.dirname(__FILE__)), 'lib')

require 'rubygems'
require 'hoe'
require './lib/signal.rb'

Hoe.new('signal', Signal::VERSION) do |p|
  p.rubyforge_name = 'signal'
  p.email = 'eric@5stops.com'
  p.author = 'Eric Lindvall'
  # p.summary = 'FIX'
  # p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  # p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

# vim: syntax=Ruby
