# LAMP + Behat + Selenium + Firefox
#

FROM ubuntu:14.04
MAINTAINER Volodymyr Dubyna <vovikha@gmail.com>

WORKDIR /tmp
# Install apache, mysql, php, composer, java, firefox, xvfb
RUN apt-get update && apt-get install -y apache2 php5 php5-curl mysql xvfb firefox
RUN apt-get install -y openjdk-7-jre-headless xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin
RUN mv /usr/bin/composer.phar /usr/bin/composer

RUN mkdir -p /usr/lib/selenium && wget http://selenium-release.storage.googleapis.com/2.43/selenium-server-standalone-2.43.1.jar /usr/lib/selenium/selenium-server-standalone.jar
ADD ./install /
RUN mkdir -p /var/log/selenium/ && chmod 777 /var/log/selenium/
RUN chmod +x /etc/init.d/selenium && update-rc.d selenium defaults
RUN chmod +x /etc/init.d/xvfb && update-rc.d xvfb defaults

ENV DISPLAY :99

# Then set the environment variables and run the gitlab-ci-runner in the container:
# docker run -e CI_SERVER_URL=https://ci.example.com -e REGISTRATION_TOKEN=replaceme -e HOME=/root -e GITLAB_SERVER_FQDN=gitlab.example.com gitlabhq/gitlab-ci-runner

# Install gitlab runner

# Get rid of the debconf messages
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get install -y curl libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libssl-dev patch build-essential zlib1g-dev openssh-server libyaml-dev libicu-dev

# Download Ruby and compile it
RUN mkdir /tmp/ruby
RUN cd /tmp/ruby && curl --silent ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p481.tar.gz | tar xz
RUN cd /tmp/ruby/ruby-2.0.0-p481 && ./configure --disable-install-rdoc && make install

RUN gem install bundler

# Set an utf-8 locale
RUN echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

# Install the runner
RUN curl --silent -L https://gitlab.com/gitlab-org/gitlab-ci-runner/repository/archive.tar.gz | tar xz
RUN cd gitlab-ci-runner.git && bundle install --deployment

WORKDIR /gitlab-ci-runner.git

# When the image is started add the remote server key, set up the runner and run it
CMD ssh-keyscan -H $GITLAB_SERVER_FQDN >> /root/.ssh/known_hosts && bundle exec ./bin/setup_and_run
