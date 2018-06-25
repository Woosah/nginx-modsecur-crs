FROM ubuntu:latest

MAINTAINER Woosah <post@woosah.info>

ENV NGINX_VERSION 1.15.0

RUN apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y && apt-get install -y wget gnupg && \
    wget "https://nginx.org/keys/nginx_signing.key" && apt-key add nginx_signing.key && \
    echo "deb http://nginx.org/packages/debian/ bionic nginx" >> /etc/apt/sources.list && \
    echo "deb-src http://nginx.org/packages/debian/ bionic nginx" >> /etc/apt/sources.list && \
    apt-get install -y nginx && \
    apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf zlib1g-dev
    
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
    tar zxvf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
    make modules && \
    mkdir /etc/nginx/modules && \
    cp /nginx-${NGINX_VERSION}/objs/ngx_http_modsecurity_module.so /etc/nginx/modules/ngx_http_modsecurity_module.so && \
    echo "load_module modules/ngx_http_modsecurity_module.so;" >> /etc/nginx/nginx.conf && \
    cd / && \
    mkdir /etc/nginx/modsec && \
    wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended && \
    mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/SecRequestBodyLimit 13107200/SecRequestBodyLimit 100000000/' /etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/SecAuditLogType Serial/SecAuditLogType Concurrent/' /etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/SecAuditLog \/var\/log\/modsec_audit.log/#SecAuditLog \/var\/log\/modsec_audit.log/' /etc/nginx/modsec/modsecurity.conf && \
    sed -i 's/#SecAuditLogStorageDir \/opt\/modsecurity\/var\/audit\//SecAuditLogStorageDir \/var\/log\/modsec_audit\//' /etc/nginx/modsec/modsecurity.conf && \
    cd /

    
RUN cd /etc/nginx/ && \
    git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git && \
    cd /etc/nginx/owasp-modsecurity-crs && \
    mv /etc/nginx/owasp-modsecurity-crs/crs-setup.conf.example /etc/nginx/owasp-modsecurity-crs/crs-setup.conf && \
    mv /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf && \
    mv /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    touch /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/modsec/modsecurity.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/crs-setup.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/*.conf;" >> /etc/nginx/modsec/modsec_includes.conf
    

RUN apt-get remove -qy --purge git wget gnupg apt-utils autoconf automake build-essential libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf zlib1g-dev && \
    apt-get purge -y --auto-remove 
    
RUN rm /nginx-${NGINX_VERSION}.tar.gz && \
    rm /nginx_signing.key && \
    rm -rf /nginx-${NGINX_VERSION} && \
    rm -rf /ModSecurity && \
    rm -rf /ModSecurity-nginx && \
    rm -rf /var/lib/apt/lists/* 
   
# forward request and error logs to docker log collector
RUN mkdir -p /var/log/modsec_audit/ && \
    mkdir -p /var/log/nginx/ && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
	  ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
