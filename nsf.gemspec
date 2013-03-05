# -*- encoding: utf-8 -*-
require File.expand_path("../lib/nsf/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "nsf"
  s.version     = Nsf::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Brenton Fletcher"]
  s.email       = ["i@bloople.net"]
  s.homepage    = "http://rubygems.org/gems/nsf"
  s.summary     = "The NSF gem is a reference implementation of the Normalized Story Format."
  s.description = "The gem facilitates conversion of text and HTML documents into NSF, as well as converting NSF to HTML. The SPEC file contains the NSF specification."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "nsf"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_dependency "nokogiri", ">= 1.4.4"
  s.add_dependency "prawn", ">= 0.0.0"
  s.add_dependency "clbustos-rtf", ">= 0.1.0"
  s.add_dependency "ruby-rtf", ">= 0.0.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
