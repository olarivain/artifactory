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
def resolve_version_url (new_resource, repository)
	# build search url
	buffer = ["#{new_resource.url}/#{repository}"]
	buffer << "/#{new_resource.group_id.split('.').join('/')}"
	buffer << "/#{new_resource.artifact_id}"
	buffer << "/#{new_resource.version}"
	buffer << "/#{new_resource.file_name_with_version}"

	buffer.join ""
end

def download_artifact (new_resource)
	success = false
	new_resource.repositories.each {|repository|
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
		artifact_url = resolve_version_url(new_resource, repository)
		download = remote_file file_name do
			source artifact_url
			mode 0644
		end

		# run the download and notifiy if updated
		begin 
			download.run_action(:create)
		rescue e
			Chef::Log.info("Couldn't fetch #{new_resource.group_id}:#{new_resource.artifact_id}:#{new_resource.version} from #{repository}: #{e}")
		end
		new_resource.updated_by_last_action(true) unless !download.updated_by_last_action?
		Chef::Log.info("Fetched #{new_resource.group_id}:#{new_resource.artifact_id}:#{new_resource.version} from #{repository}.")
		sucess = true
		break
	}
	raise "Couldn't fetch #{new_resource.group_id}:#{new_resource.artifact_id}:#{new_resource.version} from any repository." unless success
end

action :put do 
	download_artifact new_resource
end