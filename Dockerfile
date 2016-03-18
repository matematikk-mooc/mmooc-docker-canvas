FROM ubuntu:15.10
# https://github.com/instructure/canvas-lms/wiki/Production-Start#dependency-installation # Brightbox provides updated versions of passenger and ruby (http://wiki.brightbox.co.uk/docs:ruby-ng) RUN apt-get install -y software-properties-common python-software-properties
# We need a pretty new node.js
RUN apt-get -y update && \
    apt-get -y install curl apt-transport-https && \
    (curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -) &&  \
    (echo 'deb https://deb.nodesource.com/node_0.12 wily main' > /etc/apt/sources.list.d/nodesource.list) && \
    (echo 'deb-src https://deb.nodesource.com/node_0.12 wily main' >> /etc/apt/sources.list.d/nodesource.list) && \
    apt-get -y update && \
    apt-get -y install ruby ruby-dev \
    zlib1g-dev libxml2-dev libmysqlclient-dev libxslt1-dev \
    imagemagick libpq-dev libxmlsec1-dev libcurl4-gnutls-dev \
    libxmlsec1 build-essential openjdk-7-jre unzip git-core \
    libapache2-mod-passenger apache2 python-lxml libsqlite3-dev \
    ruby-passenger nodejs ruby-multi-json

RUN cd /opt && git clone --depth 1 --branch stable https://github.com/instructure/canvas-lms.git
RUN gem install bundler && gem install passenger
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
ADD cache_store.yml /opt/canvas-lms/config/
ADD redis.yml /opt/canvas-lms/config/
ADD selenium.yml /opt/canvas-lms/config/
WORKDIR /opt/canvas-lms
RUN adduser --disabled-password --gecos canvas canvasuser
RUN mkdir -p log tmp/pids public/assets public/stylesheets/compiled
RUN touch Gemfile.lock
RUN chown -R canvasuser config/environment.rb log tmp public/assets public/stylesheets/compiled Gemfile.lock config.ru
# https://github.com/instructure/canvas-lms/wiki/Production-Start#apache-configuration
ENV RAILS_ENV production
# ruby barfs at non-ascii, need to set encoding.
RUN npm install --unsafe-perm
RUN find /opt/canvas-lms/vendor/bundle/ruby \
         -name extractor.rb \
         -exec sed -i -e 's/File.read(path)/File.read(path, :encoding => "UTF-8")/' {} \; && \
    bundle exec rake canvas:compile_assets
RUN a2enmod passenger
ADD canvas_apache.conf /etc/apache2/sites-available/canvas.conf
ADD apache2-wrapper.sh /root/apache2
RUN a2dissite 000-default
RUN a2ensite canvas
EXPOSE 80
RUN cd /opt/canvas-lms/vendor && git clone https://github.com/instructure/QTIMigrationTool.git QTIMigrationTool
RUN chmod +x /opt/canvas-lms/vendor/QTIMigrationTool/migrate.py
ENTRYPOINT ["/root/apache2"]
