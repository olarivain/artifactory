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
	buffer = ["#{new_resource.url}/api/storage/#{repository}"]
	buffer << "#{new_resource.group_id.split('.').join('/')}"
	buffer << "/#{new_resource.artifact_id}"
	buffer << "/#{new_resource.version}"
	buffer << "/#{new_resource.file_name}"

	buffer.join ""
end

def download_artifact (new_resource)
	success = false
	new_resource.repositories.each {|repository|
		# resolve download url and fetch the content
		artifact_url = resolve_version_url new_resource
		begin 
			artifact_response = RestClient.get artifact_url
		rescue => e
			Chef::Log.info("Repository #{repository} answered #{e.code} on #{artifact_url}")
		end

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
		Chef::Log.info("Fetched #{new_resource.group_id}:#{new_resource.artifact_id}:#{new_resource.version} from #{repository}.")
		success
		break
	}
	raise "Failed to fetch #{new_resource.group_id}:#{new_resource.artifact_id}:#{new_resource.version} from #{new_resource.repositories} at #{new_resource.url}" unless success
end

action :put do 
	download_artifact new_resource
end