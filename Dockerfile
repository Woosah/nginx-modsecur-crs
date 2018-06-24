FROM ubuntu:latest

MAINTAINER Woosah <post@woosah.info>

ENV MODSECURITY_VERSION 3.0.0

RUN apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y && apt-get install -y wget gnupg && \
    wget "https://nginx.org/keys/nginx_signing.key" && apt-key add nginx_signing.key && \
    echo "deb http://nginx.org/packages/debian/ bionic nginx" >> /etc/apt/sources.list && \
    echo "deb-src http://nginx.org/packages/debian/ bionic nginx" >> /etc/apt/sources.list && \
    apt-get install -y nginx && \
    apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev
    
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity && \
    cd ModSecurity && \
    git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && \
    make && \
    make install && cd ../ 

RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
    wget http://nginx.org/download/nginx-1.15.0.tar.gz && \
    tar zxvf nginx-1.15.0.tar.gz && \
    cd nginx-1.13.1 && \
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
    make modules && \
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules
    
# RUN echo "SecRuleEngine On" >> modsecurity.conf

# In line 38, increase the value of "SecRequestBodyLimit" to "100000000".

# SecRequestBodyLimit 100000000

# In line 192, change the value of "SecAuditLogType" to "Concurrent" and comment out the line  SecAuditLog and uncomment line 196.

# SecAuditLogType Concurrent
#SecAuditLog /var/log/modsec_audit.log

# Specify the path for concurrent audit logging.
# SecAuditLogStorageDir /opt/modsecurity/var/audit/



#    cp /opt/modsecurity-${MODSECURITY_VERSION}/modsecurity.conf-recommended /etc/nginx/modsecurity.conf && \
#    cp /opt/modsecurity-${MODSECURITY_VERSION}/unicode.mapping /etc/nginx/ && \

#    cd /usr/src && \
#    git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git && \

#    apt-get remove -qy --purge git wget dpkg-dev apache2-dev libpcre3-dev libxml2-dev && \
#    apt-get -qy autoremove && \
#    rm -rf /opt/modsecurity-* && \
#    rm -rf /opt/nginx* && \
#    rm -rf /var/lib/apt/lists/*

RUN ln -sf /dev/stdout /var/log/modsec_audit.log
# RUN mkdir /etc/nginx/modsecurity-data && \
#    chown nginx: /etc/nginx/modsecurity-data && \
#    cat /usr/src/owasp-modsecurity-crs/crs-setup.conf.example /usr/src/owasp-modsecurity-crs/rules/*.conf > /etc/nginx/modsecurity.conf && \
#    cp /usr/src/owasp-modsecurity-crs/rules/*.data /etc/nginx/ && \
#    sed -i -e 's%location / {%location / {\n        ModSecurityEnabled on;\n        ModSecurityConfig modsecurity.conf;%' /etc/nginx/conf.d/default.conf && \
#    echo "SecAuditLog /var/log/modsec_audit.log" >> /etc/nginx/modsecurity.conf && \
#    echo "SecRuleEngine On" >> /etc/nginx/modsecurity.conf && \
#    #echo 'SecDefaultAction "phase:1,deny,log"' >> /etc/nginx/modsecurity.conf
#    echo "SecDataDir /etc/nginx/modsecurity-data" >> /etc/nginx/modsecurity.conf

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]

