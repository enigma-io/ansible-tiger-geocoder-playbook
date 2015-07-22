# Ansible Playbook for the PostGIS Tiger Geocoder



This Ansible playbook provisions and installs the basic Tiger Geocoder/Postgis setup, which automates the build of a Postgres/Postgis database that includes geography columns for U.S. States and Territories at the following summary levels:

* census block (tabblock)
* census block group (bg)
* census tract (tract)
* zipcode (zcta5)
* census county subdivision (cousub)
* county (county)
* census place (place)
* state (state)

If you are launching a fresh AWS ec2 instance, you can just use our [Amazon Machine Image](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) (id: ami-c5847eae). 

Since the AMI is the simplest solution, this playbook is perhaps most useful for someone who wants to run a local geocoder on a virtual machine, or someone who wants to add the geocoder to a pre-existing server. There are instructions for doing both of these things below.

## Features

* Install PostgreSQL
* Install Postgis
* Mount a data drive (optional, recommended!)
* Install `postgis_tiger_geocoder` extension
* Install nation-level geographies and specified state-level geographies

## Requirements

Provisioning tested on:
* Vagrant 1.6.5
* Ansible 1.7.2

Provisioned box tested with:
* Ubuntu 14.04
* Postgresql 9.3.6
* Postgis 2.1

An environment variable called `TIGER_DB_PASSWORD` with the password for your PostgreSQL instance.

## Pre-installation

* [Ansible's official installation guide](http://docs.ansible.com/intro_installation.html).


* [Vagrant's official installation guide](http://docs.vagrantup.com/v2/installation/).

If you are using Vagrant, you'll also need to download [Virtualbox](https://www.virtualbox.org/).

## Running the playbook

Ansible is "the simplest way to automate apps and IT infrastructure". Vagrant enables one to "create and configure lightweight, reproducible, and portable development environments." Using one or both of them with this playbook will allow you to launch the Tiger geocoder.

### Local Vagrant Install

For a **local** virtual machine, setup depends on your local system. Make sure you've installed Vagrant, Ansible and Virtualbox (see above links). Then:
```
git clone https://github.com/enigma-io/ansible-tiger-geocoder-playbook.git
cd ansible-tiger-geocoder-playbook
# This is intended to be run from the main repo directory
sh setup/fetch-tiger-geocoder-role.sh
# This uses the Vagrantfile included in the home directory of this repo.
vagrant up tiger
```

### AWS Install

For a **remote** AWS instance, a few things to be aware of:

* You'll probably want to use a mounted drive since the Tiger dataset will far exceed the default disk drive for an instance.


Once you've provisioned a new AWS box and ssh'd in, get the playbook repo. 

```
sudo apt-get update
sudo apt-get install git
git clone https://github.com/enigma-io/ansible-tiger-geocoder-playbook.git
cd ansible-tiger-geocoder-playbook
```

Then run a script that sets up the Ansible role in the proper folder:
```
sudo chmod +x ./setup/fetch-tiger-geocoder-role.sh
sudo sh ./setup/fetch-tiger-geocoder-role.sh
```

Then run a script that installs Ansible:

```
sudo chmod +x ./setup/ansible-ubuntu-setup.sh
sudo sh ./setup/ansible-ubuntu-setup.sh
```

Store the password for your postgres database:

```
echo 'export TIGER_DB_PASSWORD=changeme' >> ~/.bashrc
source ~/.bashrc
```

Then open a screen. Running the playbook in a screen will make running this ~24 hour process a lot less annoying!

```
screen -S load_tiger
```

Then, execute the ansible-playbook command:

```
ansible-playbook -i localhost, -vv \
    /home/ubuntu/ansible-tiger-geocoder-playbook/provisioning/tigergeocoder.yml \
    --extra-vars="tiger_local_vm=false tiger_mounted_drive_path=/dev/xvdb" \
    --connection=local 

```

Now you can let the playbook run. Consult `man screen` for more details, but to safely exit the screen enter: `ctrl-a ctrl-d`, and to re-enter the screen to see how it's progressing, you can type `screen -r load_tiger`.

## How It Works


The playbook deals with a number of `pre_task` steps that are not included in our official `tiger-geocoder` role that make it easy to spin up a fresh local or remote instance with all the requirements to get a geocoder running. That includes installing Postgres and PostGIS, and mounting a data drive.


### Choosing States/Territories to include

All possible two-letter abbrevations to download and load into the geocoder are included at `provisioning/roles/tiger-geocoder/defaults/main.yml` in the variable`tiger_geos`.

Comment out those you're not interested in including.

**Warning**: The role comes with ALL possible variables uncommented!

### DB Password

You must store the password to your database as a local environment variable named `TIGER_DB_PASSWORD`.

### Storage

The playbook is pre-set to assume you will be using a mounted drive, but you can turn this functionality off if you want. 

A mounted drive accommodates the size requirement of installing the geocoder for all possible U.S. States and Territories, which amounts to nearly a hundred gigabytes. If you wanted to download just a part of the data (the state of Wisonsin, perhaps), then you'll have less need of a mounted drive.


##### Turn off mounted drive option

**Locally:**
Remove the line that starts with `tiger_mounted_drive_path` in the `Vagrantfile` in the home directory of this repo.

**On AWS:***
Remove the `tiger_mounted_drive_path` arg from the command-line option in the directions above.


###### Local mounted drive
You can run a local geocoder and host the data itself on a local mounted drive. 

In order to do this, specify the value for the `file_to_disk` key located in the `tiger_vb_mount` field in `tiger-local-vm.json` in the home directory of this repo. 

The default is currently set to `./tmp/tiger_mounted_drive.vdi.`, but it could ostensibly be changed to `/Volumes/your_mounted_4TB/geocoder.vdi`.


### Provisioning Time

Provisioning the entire Tiger dataset will take a long time! If you plan to include every State and Territory, plan to either have your computer running for upwards of 24 hours, or run the playbook in a screen on a remote host.

### Logging in

After running the provision script, you should be able to log in to your box with the command `vagrant ssh`, log in to postgres via the `psql` cli like:

`psql -d yourdb -U postgres -h localhost`

You'll be prompted for your password. You should have set this with your local environment variable `TIGER_DB_PASSWORD` (see the 'DB Password' section).

Once logged in, you can run a query like:

```
geocoder=# select * from geocode('1600 Pennsylvania Avenue Northwest, Washington, DC 20500');
```

with results:
```
                        addy                        |                      geomout                       | rating 
----------------------------------------------------+----------------------------------------------------+--------
 (1600,,Pennsylvania,Ave,NW,,Washington,DC,20502,t) | 0101000020AD100000FF3316523F4253C0101234A607734340 |      2
```

Keep in mind that you now have access to PostGIS functions along with the suite of functions that the Tiger Geocoder offers. Documentation for both can be found at [http://postgis.net/docs/](http://postgis.net/docs/)


## Additional Tiger Data

As mentioned, this playbook builds the base-level Tiger geocoder that comes from scripts generated by invoking the `load_generate` scripts built into the `postgis_tiger_geocoder` Postgis extension.

If you want to load other summary levels, you can do so by running a script that takes the form:

`shp2pgsql -c -s 4269 -g the_geom -W "latin1" tl_2013_us_cbsa.dbf tiger.cbsa | psql`

and then improve the speed of your queries by indexing the geometry file in the table, like:

`create index tiger_cbsa_the_geom_gist ON tiger.cbsa USING gist (the_geom);`

where you replace 'cbsa' with the census summary level you're interested in adding to the database.
