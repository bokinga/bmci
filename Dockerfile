FROM centos:6.7 
MAINTAINER Russell Kirkland <russell@fffunction.co> 

# install http 
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

# install httpd 
RUN yum -y install httpd vim-enhanced bash-completion unzips

# install php 
RUN rpm -Uvh http://mirror.webtatic.com/yum/el6/latest.rpm
RUN yum install -y php55w php55w-mysql php55w-devel php55w-gd php55w-pecl-memcache php55w-pspell php55w-snmp php55w-xmlrpc php55w-xml

# install supervisord 
RUN yum install -y python-pip && pip install pip --upgrade
RUN pip install meld3==1.0.0
RUN pip install supervisor

# install sshd 
RUN yum install -y openssh-server openssh-clients passwd

RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key 
RUN sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config && echo 'root:changeme' | chpasswd

# ssl 
RUN yum install -y mod_ssl openssl

# forward request and error logs to docker log collector
RUN mkdir /var/log/apache2
RUN ln -sf /dev/stdout /var/log/apache2/access-ssl.log && ln -sf /dev/stderr /var/log/apache2/error-ssl.log

# Create SSL certificate
RUN mkdir -p /etc/apache2/ssl/ && \
    openssl req -x509 -nodes -sha256 -days 3650 -subj "/C=GB/ST=London/CN=localhost" -newkey rsa:2048 -keyout "/etc/apache2/ssl/key.pem" -out "/etc/apache2/ssl/cert.pem"

# Install git and mysql
RUN yum install -y git
RUN	yum install -y mysql

# Install utils
RUN yum install -y bzip2
RUN yum install -y tar

# phantomjs deps
RUN yum install -y build-essential chrpath libssl-dev libxft-dev
RUN	yum install -y fontconfig freetype freetype-devel fontconfig-devel libstdc++

# Install PhantomJS
RUN curl -Lo /var/tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
RUN	tar xvjf /var/tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /var/tmp
RUN	ln -sf /var/tmp/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin

# Install CasperJS
RUN git clone git://github.com/casperjs/casperjs.git /var/tmp/casperjs
RUN	ln -sf /var/tmp/casperjs/bin/casperjs /usr/local/bin/casperjs

# Install phpunit
RUN curl -Lo /usr/local/bin/phpunit https://phar.phpunit.de/phpunit-old.phar
RUN	chmod +x /usr/local/bin/phpunit

# Install wp-cli
RUN curl -Lo /var/tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN	chmod +x /var/tmp/wp-cli.phar
RUN	mv /var/tmp/wp-cli.phar /usr/local/bin/wp


ADD ./supervisord.conf /etc/
ADD ./default.conf /etc/httpd/conf.d/default.conf
EXPOSE 22 80 443
CMD ["supervisord", "-n"]