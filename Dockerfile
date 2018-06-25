FROM ubuntu:latest

MAINTAINER Woosah <post@woosah.info>

ENV NGINX_VERSION 1.15.0

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
    
RUN git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git && \
    cd /etc/nginx/owasp-modsecurity-crs && \
    mv /etc/nginx/owasp-modsecurity-crs/crs-setup.conf.example /etc/nginx/owasp-modsecurity-crs/crs-setup.conf && \
    mv /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf && \
    mv /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf && \
    touch /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/modsec/modsecurity.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/crs-setup.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-901-INITIALIZATION.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-905-COMMON-EXCEPTIONS.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-910-IP-REPUTATION.conf" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-911-METHOD-ENFORCEMENT.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-912-DOS-PROTECTION.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-913-SCANNER-DETECTION.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-921-PROTOCOL-ATTACK.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-949-BLOCKING-EVALUATION.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-950-DATA-LEAKAGES.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-959-BLOCKING-EVALUATION.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-980-CORRELATION.conf;" >> /etc/nginx/modsec/modsec_includes.conf && \
    echo "include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf;" >> /etc/nginx/modsec/modsec_includes.conf
    
RUN rm /nginx-${NGINX_VERSION}.tar.gz && \
    rm /nginx_signing.key && \
    rm -rf /nginx-${NGINX_VERSION} && \
    rm -rf /ModSecurity && \
    rm -rf /ModSecurity-nginx && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get remove -qy --purge git wget gnupg apt-utils autoconf automake build-essential libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf zlib1g-dev ca-certificates dirmngr gnupg-l10n gnupg-utils gpg gpg-agent gpg-wks-client gpg-wks-server gpgconf gpgsm libasn1-8-heimdal libassuan0 libgssapi3-heimdal libhcrypto4-heimdal libheimbase1-heimdal libheimntlm0-heimdal libhx509-5-heimdal libkrb5-26-heimdal libksba8 libldap-2.4-2 libldap-common libnpth0 libpsl5 libreadline7 libroken18-heimdal libsasl2-2 libsasl2-modules libsasl2-modules-db libsqlite3-0 libssl1.1 libwind0-heimdal openssl pinentry-curses publicsuffix readline-common dbus-user-session libpam-systemd pinentry-gnome3 tor parcimonie xloadimage scdaemon libsasl2-modules-gssapi-mit | libsasl2-modules-gssapi-heimdal libsasl2-modules-ldap libsasl2-modules-otp libsasl2-modules-sql pinentry-doc readline-doc fontconfig-config fonts-dejavu-core geoip-database libbsd0 libexpat1 libfontconfig1 libfreetype6 libgd3 libgeoip1 libicu60 libjbig0 libjpeg-turbo8 libjpeg8 libnginx-mod-http-geoip libnginx-mod-http-image-filter libnginx-mod-http-xslt-filter libnginx-mod-mail libnginx-mod-stream libpng16-16 libtiff5 libwebp6 libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 libxml2 libxpm4 libxslt1.1 multiarch-support nginx nginx-common nginx-core ucf apt-utils autoconf automake autotools-dev binutils binutils-common binutils-x86-64-linux-gnu build-essential cpp cpp-7 dpkg-dev fakeroot file g++ g++-7 gcc gcc-7 gcc-7-base geoip-bin gir1.2-glib-2.0 gir1.2-harfbuzz-0.0 git git-man icu-devtools krb5-locales less libalgorithm-diff-perl libalgorithm-diff-xs-perl libalgorithm-merge-perl libapt-inst2.0 libasan4 libatomic1 libbinutils libc-dev-bin libc6-dev libcc1-0 libcilkrts5 libcurl3-gnutls libcurl4 libcurl4-openssl-dev libdpkg-perl libedit2 libelf1 liberror-perl libfakeroot libfile-fcntllock-perl libgcc-7-dev libgdbm-compat4 libgdbm5 libgeoip-dev libgirepository-1.0-1 libglib2.0-0 libglib2.0-bin libglib2.0-data libglib2.0-dev libglib2.0-dev-bin libgomp1 libgraphite2-3 libgraphite2-dev libgssapi-krb5-2 libharfbuzz-dev libharfbuzz-gobject0 libharfbuzz-icu0 libharfbuzz0b libicu-dev libicu-le-hb-dev libicu-le-hb0 libiculx60 libisl19 libitm1 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 liblmdb-dev liblmdb0 liblocale-gettext-perl liblsan0 libltdl-dev libltdl7 libmagic-mgc libmagic1 libmpc3 libmpdec2 libmpfr6 libmpx2 libnghttp2-14 libpcre++-dev libpcre++0v5 libpcre16-3 libpcre3-dev libpcre32-3 libpcrecpp0v5 libperl5.26 libpython3-stdlib libpython3.6-minimal libpython3.6-stdlib libquadmath0 librtmp1 libsigsegv2 libssl1.0.0 libstdc++-7-dev libtool libtsan0 libubsan0 libxext6 libxml2-dev libxmuu1 libyajl-dev libyajl2 linux-libc-dev lmdb-doc m4 make manpages manpages-dev mime-support netbase openssh-client patch perl perl-modules-5.26 pkgconf python3 python3-distutils python3-lib2to3 python3-minimal python3.6 python3.6-minimal shared-mime-info xauth xdg-user-dirs xz-utils zlib1g-dev && \
    apt-get purge -y --auto-remove 
    

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
	  ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]

