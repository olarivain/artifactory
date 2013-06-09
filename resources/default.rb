#
# Cookbook Name:: artifactory
# Provider:: default
#
# Copyright 2013, OpenTable, Inc.
#
# All rights reserved - Do Not Redistribute
#

actions :put

attribute :artifact_id, :kind_of => String
attribute :group_id, :kind_of => String, :required => true
attribute :dest, :kind_of => String, :required => true
attribute :version, :kind_of => String, :required => true
attribute :classifier, :kind_of => String
attribute :packaging, :kind_of => String, :default => "jar"
attribute :owner, :kind_of => String, :default => "root"
attribute :mode, :kind_of => Integer, :default => 0644
attribute :repository, :kind_of => String
attribute :url, :kind_of => String

alias :artifactId :artifact_id 
alias :groupId :group_id 

def initialize(*args)
  super
  # we can't use the node properties when initially specifying the resource
  @artifact_id ||= @name
  @repository ||= node[:artifactory][:repository]
  # remove trailing slash, we don't want double slashes in our urls
  @url ||= node[:artifactory][:url].chomp "/"
  @action = :put
end

def file_name
	filename = artifact_id
	filename += "-#{@classifier}" unless @classifier == nil
	packaging = if @packaging == nil then "jar" else @packaging end
	filename += ".#{packaging}"
	return filename
end

def file_name_with_version
  filename = artifact_id
  filename += "-#{@classifier}" unless @classifier == nil
  filename += "-#{@version}"
  packaging = if @packaging == nil then "jar" else @packaging end
  filename += ".#{packaging}"
  return filename
end