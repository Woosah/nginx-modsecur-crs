# nginx-modsecurity with OWASP v3 core rules

## Description

This docker image is build on ubuntu 18.04 bionic, with a nginx 1.15.0 webserver that has modsecurity v3 and OWASP3 v3 core rules installed.

Originally forked from nodeintegration/nginx-modsecurity, but after the automated build failed updated from scratch using the newer versions.

### The following directories / files are of interest

##### Put a docker volume with read-only to this file to configure the server:
  
    /etc/nginx/conf.d/default.conf


##### OWASP v3 rules includes file:

    /etc/nginx/modsec/modsec_includes.conf

##### OWASP v3 rules configuration file:

    /etc/nginx/owasp-modsecurity-crs/crs-setup.conf

##### ModSecurity configuration file:

    /etc/nginx/modsec/modsecurity.conf


##### Log-files:

###### Normal log-files:

    /var/log/nginx/access.log
     /var/log/nginx/error.log
  

###### ModSecurity Concurrent Audit Log:
  
    /var/log/modsec_audit/


