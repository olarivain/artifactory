#
# Cookbook Name:: artifactory
# Provider:: default
#
# Copyright 2013, OpenTable, Inc.
#
# All rights reserved - Do Not Redistribute
#

# make sure the rest_client gem is loaded
require 'rubygems'
require 'rest_client'

# /api/search/gavc?g=org.acme&a=artifact&v=1.0&c=sources&repos=libs-release-local
def resolve_version_url (new_resource)
	# build search url
	buffer = ["#{new_resource.url}/#{new_resource.repository}"]
	buffer << "/#{new_resource.group_id.split('.').join('/')}"
	buffer << "/#{new_resource.artifact_id}"
	buffer << "/#{new_resource.version}"
	buffer << "/#{new_resource.file_name_with_version}"

	buffer.join ""
end

def download_artifact (new_resource)
	# create relevant resources along the way
	FileUtils.mkdir_p new_resource.dest unless ::File.exist? new_resource.dest
	# derive the filename now
	if !::File.file? new_resource.dest then
		file_name = (Pathname(new_resource.dest) + new_resource.file_name).to_s
	else
		# unless we've been given a path to a file, in which case, override it
		file_name = new_resource.dest
	end

	# resolve download url and fetch the content
	artifact_url = resolve_version_url(new_resource)
	download = remote_file file_name do
		source artifact_url
	end

	# run the download and notifiy if updated
	download.run_action(:create)
	new_resource.updated_by_last_action(true) unless !download.updated_by_last_action?
	Chef::Log.info("Fetched #{new_resource.group_id}:#{new_resource.artifact_id}:#{new_resource.version} from #{new_resource.repository}.")
end

action :put do 
	download_artifact new_resource
end