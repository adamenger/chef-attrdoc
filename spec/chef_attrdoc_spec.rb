# -*- coding: utf-8 -*-

# Copyright 2013, Ionuț Arțăriși <ionut@artarisi.eu>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef_attrdoc'


describe ChefAttrdoc do
  ["TODO bar", "XXX foo bar", "NOTE(me) nasty bug",
    ":pragma-foodcritic: ~FC024 - won't fix this"].each do |comm|
    it "should ignore \"#{comm}\" comment" do
      text = <<END
# #{comm}
# good comment
default[good] = 'comment'
END
      ca = ChefAttrdoc::AttributesFile.new(text)
      expect(ca.groups).to eq([["default[good] = 'comment'\n", "# good comment\n"]])
    end
  end

  it "groups comments and several lines of code together" do
    text = <<END
# first block
default[foo] = 'bar'
default[bar] = 'baz'

# ignored comment

# second block
node.set[baz] = 'qux'
node.set[foo] = 'qux'
node.set[bar = 'qux'
END
    ca = ChefAttrdoc::AttributesFile.new(text)
    expect(ca.groups).to eq([
        ["default[foo] = 'bar'\ndefault[bar] = 'baz'\n",
          "# first block\n"],
        ["node.set[baz] = 'qux'\nnode.set[foo] = 'qux'\nnode.set[bar = 'qux'\n",
          "# second block\n"]])
  end

  it "ignores code without comments" do
text = <<END
# first block
default[foo] = 'bar'
default[bar] = 'baz'

default[ignored] = false

# second block
node.set[baz] = 'qux'
END
    ca = ChefAttrdoc::AttributesFile.new(text)
    expect(ca.groups).to eq([
        ["default[foo] = 'bar'\ndefault[bar] = 'baz'\n", "# first block\n"],
        ["node.set[baz] = 'qux'\n", "# second block\n"]])
  end

  it "ignores the first comments in a file" do
    text = <<END
# Copyright
# foo

# bar

# this is important
default[foo] = 'bar'
END
    ca = ChefAttrdoc::AttributesFile.new(text)
    expect(ca.groups).to eq([["default[foo] = 'bar'\n", "# this is important\n"]])
  end

  it "handles platform group with lots of branches and hashes" do
    text = <<END
# platform specific attributes
case platform
when "fedora", "redhat", "centos" # :pragma-foodcritic: ~FC024 - won't fix this
  default["openstack"]["identity"]["user"] = "keystone"
  default["openstack"]["identity"]["group"] = "keystone"
  default["openstack"]["identity"]["platform"] = {
    "memcache_python_packages" => [ "python-memcached" ],
    "keystone_packages" => [ "openstack-keystone" ],
    "keystone_process_name" => "keystone-all",
    "package_options" => ""
  }
when "suse"
  default["openstack"]["identity"]["user"] = "openstack-keystone"
  default["openstack"]["identity"]["platform"] = {
    "mysql_python_packages" => [ "python-mysql" ],
    "memcache_python_packages" => [ "python-python-memcached" ],
    "keystone_process_name" => "keystone-all",
    "package_options" => ""
  }
END
    ca = ChefAttrdoc::AttributesFile.new(text)
    expect(ca.groups).to eq(
      [["case platform\n"\
        "when \"fedora\", \"redhat\", \"centos\" "\
        "  default[\"openstack\"][\"identity\"][\"user\"] = \"keystone\"\n"\
        "  default[\"openstack\"][\"identity\"][\"group\"] = \"keystone\"\n"\
        "  default[\"openstack\"][\"identity\"][\"platform\"] = {\n"\
        "    \"memcache_python_packages\" => [ \"python-memcached\" ],\n"\
        "    \"keystone_packages\" => [ \"openstack-keystone\" ],\n"\
        "    \"keystone_process_name\" => \"keystone-all\",\n"\
        "    \"package_options\" => \"\"\n"\
        "  }\n"\
        "when \"suse\"\n"\
        "  default[\"openstack\"][\"identity\"][\"user\"] = \"openstack-keystone\"\n"\
        "  default[\"openstack\"][\"identity\"][\"platform\"] = {\n"\
        "    \"mysql_python_packages\" => [ \"python-mysql\" ],\n"\
        "    \"memcache_python_packages\" => [ \"python-python-memcached\" ],\n"\
        "    \"keystone_process_name\" => \"keystone-all\",\n"\
        "    \"package_options\" => \"\"\n"\
        "  }\n",
        "# platform specific attributes\n"]])
  end
  end
end
