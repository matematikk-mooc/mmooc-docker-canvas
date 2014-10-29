FROM ubuntu:12.04

RUN apt-get -y update

# https://github.com/instructure/canvas-lms/wiki/Production-Start#dependency-installation

# Brightbox provides updated versions of passenger and ruby (http://wiki.brightbox.co.uk/docs:ruby-ng)

RUN apt-get install -y software-properties-common python-software-properties
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update

RUN apt-get install -y ruby1.9.3 \
    zlib1g-dev libxml2-dev libmysqlclient-dev libxslt1-dev \
    imagemagick libpq-dev libxmlsec1-dev libcurl4-gnutls-dev \
    libxmlsec1 build-essential openjdk-7-jre unzip

# RUN apt-get install -y python-software-properties python g++ make
RUN add-apt-repository ppa:chris-lea/node.js
RUN apt-get update
RUN apt-get install -y nodejs


RUN apt-get install -y git-core
RUN cd /opt && git clone --depth 1 --branch stable https://github.com/matematikk-mooc/canvas-lms.git


RUN gem install bundler --version 1.5.3
RUN cd /opt/canvas-lms && bundle install --path vendor/bundle --without=sqlite

ADD amazon_s3.yml /opt/canvas-lms/config/
ADD database.yml /opt/canvas-lms/config/
ADD delayed_jobs.yml /opt/canvas-lms/config/
ADD domain.yml /opt/canvas-lms/config/
ADD file_store.yml /opt/canvas-lms/config/
ADD outgoing_mail.yml /opt/canvas-lms/config/
ADD security.yml /opt/canvas-lms/config/
ADD external_migration.yml /opt/canvas-lms/config/
ADD saml.yml /opt/canvas-lms/config/


WORKDIR /opt/canvas-lms

RUN adduser --disabled-password --gecos canvas canvasuser
RUN mkdir -p log tmp/pids public/assets public/stylesheets/compiled
RUN touch Gemfile.lock
RUN chown -R canvasuser config/environment.rb log tmp public/assets public/stylesheets/compiled Gemfile.lock config.ru

WORKDIR /

# https://github.com/instructure/canvas-lms/wiki/Production-Start#apache-configuration

ENV RAILS_ENV production
WORKDIR /opt/canvas-lms
RUN npm install
RUN bundle exec rake canvas:compile_assets
WORKDIR /

RUN apt-get update

RUN apt-get install -y passenger-common1.9.1 libapache2-mod-passenger apache2
RUN a2enmod passenger

ADD canvas_apache.conf /etc/apache2/sites-available/canvas
ADD apache2-wrapper.sh /root/apache2

RUN a2dissite default
RUN a2ensite canvas

EXPOSE 80 443

CMD ["bin/bash", "/root/apache2"]
