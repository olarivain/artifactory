#
# Cookbook Name:: artifactory
# Provider:: default
#
# Copyright 2013, OpenTable, Inc.
#
# All rights reserved - Do Not Redistribute
#

actions :put, :none

attribute :artifact, :kind_of => Artifactory::Artifact
attribute :dest, :kind_of => String, :required => true
attribute :owner, :kind_of => String, :default => "root"
attribute :mode, :kind_of => Integer, :default => 0644

def initialize(*args)
  super

  @action = :put
end