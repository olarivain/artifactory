artifactory Cookbook
====================
Downloads artifacts from an Artifactory instance. It's usage is very similar to the maven cookbook provided by OpsCode.
User provides artifact GAVC coordinates, the provider resolves them against Artifactory and eventually uses a remote file resource to fetch locally.

Requirements
------------
None.

Attributes
----------
See `attributes/default.rb` for default values.

* `default["artifactory"]["url"]` - the url to the artifactory server, e.g. http://artifactory.example.com:8081/artifactory. Required. The provider handles the presence or absence of a trailing slash gracefully.
* `default["artifactory"]["repository"]` - repository to resolve artifacts from. Defaults to "internal". Required. Currently only one repository is supported, more will be in a near future.

Usage
-----
Make sure you override the artifactory url first.
Also make sure the repository matches yours.
Then:

```ruby
artifactory "artifact-id" do
  group_id "groupid"
  version "1.0.42"
  classifier "sources" # optional, defaults to nil
  packaging "war" # defaults to jar
  dest "file_path_destination"
  action :put
end
```

If the destination path is a folder, then the artifact will be created as DEST_PATH/artifact_id.packaging.  
If the destination path is an existing file, then the artifact will be created as DEST_PATH (overwrites it).

License and Authors
-------------------
Authors: Olivier Larivain
