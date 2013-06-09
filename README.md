artifactory Cookbook
====================
Downloads artifacts from Artifactory. It's usage is very similar to the maven cookbook provided by OpsCode.
User provides artifact GAVC coordinates, the provider resolves them against Artifactory and eventually uses a remote file resource to fetch locally.

Requirements
------------
None.

Attributes
----------
See `attributes/default.rb` for default values.

* `default["artifactory"]["url"]` - the url to the artifactory server, e.g. http://artifactory.example.com:8081/artifactory. Required
* `default["artifactory"]["repository"]` - repository to resolve artifacts from. Defaults to "internal". Currently only one repository is supported, more will be in a near future.

Usage
-----
Make sure you override the artifactory url first.
Also make sure the repository matches yours.
Then:

```ruby
artifactory "artifact-id" do
  group_id "groupid"
  version theVersion
  packaging "war" # defaults to jar
  dest "file_path_destination"
  action :put
end
```

License and Authors
-------------------
Authors: Olivier Larivain
