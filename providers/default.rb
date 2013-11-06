#
# Cookbook Name:: artifactory
# Provider:: default
#
# Copyright 2013, OpenTable, Inc.
#
# All rights reserved - Do Not Redistribute
#

include Artifactory

def download_artifact (resource)
	artifact = resource.artifact

	#resolve the version if needed
	artifact.resolve_version if artifact.resolved_version == nil

	# create relevant resources along the way
	FileUtils.mkdir_p resource.dest unless ::File.exist? resource.dest

	# derive the filename now
	if !::File.file? resource.dest then
		file_name = (Pathname(resource.dest) + artifact.file_name_with_version).to_s
	else
		# unless we've been given a path to a file, in which case, override it
		file_name = resource.dest
	end

	# resolve download url and fetch the content
	artifact_url = artifact.download_url
	Chef::Log.info("attempting to fetch #{artifact.resolved_version} from #{artifact_url}")
	begin 
		download = remote_file file_name do
			source artifact_url
			mode 0644
			action :create
		end
	rescue Exception => e
		raise "Couldn't fetch #{artifact.group_id}:#{artifact.artifact_id}:#{artifact.resolved_version} from any repository."
	end

	resource.updated_by_last_action(download.updated_by_last_action?)
	Chef::Log.info("Fetched #{artifact.group_id}:#{artifact.artifact_id}:#{artifact.resolved_version} from any #{artifact.repository}.")
end

action :put do 
	download_artifact new_resource
end

action :none do
end