require 'rubygems'
require "rexml/document"
require 'restclient'

module Artifactory

	class Artifact

		attr_accessor :group_id, :artifact_id, :version, :classifier, :packaging, :repository, :base_url, :resolved_version
		
		def self.from_resource(resource)
			return Artifactory::Artifact.new(resource.group_id, resource.artifact_id, resource.version, resource.packaging, resource.repository, resource.url)
		end

		def initialize(groupd_id, artifact_id, version, packaging, repository, base_url)
			@group_id = groupd_id
			@artifact_id = artifact_id
			@version = Artifactory::Version.new(version)
			@packaging = packaging
			@repository = repository
			@base_url = base_url
		end

		def resolve_version
			if !@version.is_version_range then
				@resolved_version = @version.version
				return
			end
			# get the version list
			all_versions = version_list

			# build a version for our artifact so we can easily get the min/max
			min_version = version.min_version
			max_version = version.max_version

			# then compare all elements in the sorted array until we get the latest that still matches
		    all_versions.each do |candidate|
		        # compare to min version
		        minComparison = candidate.compare min_version 
		        
		        # we're below the min version, skip to next
		        if  minComparison < 0 then
		            next
		        end
		        
		        # compare to max version
		        maxComparison = candidate.compare max_version
		        
		        # we are below max version, or equal with inclusive flag set, we have a candidate
		        if maxComparison < 0 then
		            @resolved_version = candidate.version
		        else
		            break
		        end
		    end

		    if @resolved_version != nil then
		    	Chef::Log.info("Artifact #{@group_id}:#{@artifact_id}:#{@version} resolved to #{@resolved_version}.")
			else
				Chef::Log.info("Could not resolve artifact #{@group_id}:#{@artifact_id}:#{@version} resolved to any version.")
			end
		end

		# /api/search/gavc?g=org.acme&a=artifact&v=1.0&c=sources&repos=libs-release-local
		def download_url
		  buffer = ["#{@base_url}/#{@repository}"]
		  buffer << "/#{@group_id.split('.').join('/')}"
		  buffer << "/#{@artifact_id}"
		  buffer << "/#{@resolved_version}"
		  buffer << "/#{file_name_with_version}"
		  buffer.join ""
		end

		def file_name
			filename = @artifact_id
			filename += "-#{@classifier}" unless @classifier == nil
			filename += ".#{@packaging}"
		end

		def file_name_with_version
		  filename = @artifact_id
		  filename += "-#{@classifier}" unless @classifier == nil
		  filename += "-#{@resolved_version}"
		  filename += ".#{@packaging}"
		end

		def folder_name
		  filename = artifact_id
		  filename += "-#{@classifier}" unless @classifier == nil
		  filename += "-#{@resolved_version}"
		  return filename
		end

		private
		def version_list
			begin 
				# fetch the list of versions from artifactory
				RestClient.proxy = ENV['http_proxy']
		        response = RestClient.get metadata_url
			rescue Exception => e
				Chef::Log.info("Couldn't list versions for #{@group_id}:#{@artifact_id}:#{@version.version} from #{@repository}.\nAttempted url was #{metadata_url}")
				return
			end

			# parse it
			versions_xml = REXML::Document.new(response.to_str)
			versions_xml = REXML::XPath.match(versions_xml.root, "versioning/versions/version/text()")
			versions = []
			versions_xml.each{|version_xml|
				versions << Artifactory::Version.new(version_xml.value)
			}
			# and sort it
			versions.sort {|a, b| a.compare(b) }
			return versions
		end

		# /internal/com/opentable/mobile/mobile-rest/maven-metadata.xml
		def metadata_url
		  buffer = ["#{@base_url}/#{@repository}"]
		  buffer << "/#{@group_id.split('.').join('/')}"
		  buffer << "/#{@artifact_id}"
		  buffer << "/maven-metadata.xml"
		  buffer.join ""
		end

	end

	class Version
		attr_reader :versionComponents, :version
    
	    def initialize(version)
	        @version = version
	        
	        @versionComponents = Array.new
	        
	        versionComponents = version.split "."
	        versionComponents.each do |versionComponent| 
	             @versionComponents.push versionComponent.to_i
	        end
	    end

	    def is_version_range
		  @version.strip.start_with? "~>"
		end
	    
	    def min_version
	    	if !is_version_range then
	    		return Artifactory::Version.new(@version)
	    	end

	    	minVersion = @version.strip.gsub("~>", "")
	    	inclusive = minVersion.start_with? "="
	    	minVersion = minVersion.strip.gsub("=", "").strip

	    	if inclusive then
	    		return minVersion
	    	end

	    	components = minVersion.split "."
	    	minorNumber = components.pop.to_i + 1
	    	components << minorNumber.to_s

	    	Version.new(components.join("."))
	    end
	    
	    def max_version
	    	
	    	maxVersion = @version.strip.gsub("~>", "")
	    	maxVersion = maxVersion.strip.gsub("=", "").strip

	    	components = maxVersion.split "." 
	    	components.pop
	    	majorVersion = components.pop.to_i + 1
	    	components << majorVersion.to_s
	    	components << "0"

	    	Version.new(components.join("."))
	    end

	    def compare(other)
	        index = 0
	        otherVersionNumbers = other.versionComponents
	        
	        @versionComponents.each do |versionNumber|
	            # pragma self is longer, we got her with an equality, that means the self is 
	            # a later version, hence return 1
	            if index >= otherVersionNumbers.length then
	                return 1
	            end
	            
	            # get the other version number for the same index
	            otherVersionNumber = otherVersionNumbers[index]
	            # increment position index
	            index += 1
	            
	            # they're equal, so move on to the next
	            if versionNumber == otherVersionNumber then
	                next
	            end
	            
	            # we are smaller than the other, we're earlier, hence smaller
	            if versionNumber < otherVersionNumber then
	                return -1
	            end
	            
	            # we are bigger, we are later return 1
	            return 1
	        end
	        
	        # all numbers are equal and the arrays are the same size: the version are the same
	        if @versionComponents.length == otherVersionNumbers.length then
	            return 0
	        else
	            # all numbers are equal so far and other is longer, it is a later version
	            return -1
	        end
	    end
	end
end