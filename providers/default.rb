#
# Cookbook Name:: artifactory
# Provider:: default
#
# Copyright 2013, OpenTable, Inc.
#
# All rights reserved - Do Not Redistribute
#

# make sure the rest_client gem is loaded
r = gem_package "rest_client" do
  action :nothing
end
r.run_action(:install)
require 'rubygems'
Gem.clear_paths

require 'rest_client'

# /api/search/gavc?g=org.acme&a=artifact&v=1.0&c=sources&repos=libs-release-local
def resolve_version_url (new_resource)
	# build search url
	buffer = ["#{new_resource.url}/api/storage/internal/"]
	buffer << "#{new_resource.group_id.split('.').join('/')}"
	buffer << "/#{new_resource.artifact_id}"
	buffer << "/#{new_resource.version}"
	buffer << "/#{new_resource.file_name}"

	buffer.join ""
end

def download_artifact (new_resource)
	# resolve download url and fetch the content
	artifact_url = resolve_version_url new_resource
	artifact_response = RestClient.get artifact_url
	raise "Received #{artifact_response.code} from #{artifact_url}." unless  artifact_response.code == 200

	# create relevant resources along the way
	mkdir_p new_resource.path unless File.exists? new_resource.path
	# derive the filename now
	if !File.file? new_resource.path then
		file_name = (new Pathname(new_resource.path) + new_resource.file_name).to_s
	else
		# unless we've been given a path to a file, in which case, override it
		file_name = new_resource.path
	end

	# and eventually, write the file. We're done here
	File.open(file_name, 'w'){|f| f << response.artifact_response}
end

action :put do 
	download_artifact new_resource
end