# apache ip based access control
allow ip based access to a apache site using home assistant as control center.

![afbeelding](https://github.com/Bram-diederik/apache-HA-access/assets/53519837/75d33e7f-bd97-467d-b26c-942bcce52f41)

I have an home based server with some websites for my own use.
I noticed loads of systems make connection to my websites. Even I'm trying hard to hide them. 

This project contains 3 apache2 website snippets. 

# allow-list-site.conf
This example needs an allowed ip to operate. 
new ip's are send to home assistant where access can be granted or denied.

# deny-list-site.conf
This example allows all access unless the ip is on the denylist.

# honey-pot.conf
This example automatically adds the ip to the denylist.
use a website that should not be known for the public. and automaticly denies loads of scanners. 
