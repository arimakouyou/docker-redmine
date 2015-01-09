FROM ubuntu:14.10
MAINTAINER Kouyou Arima<arimakouyou@gmail.com>

ENV SQL_ROOT_PASS e85V0htzol2pjNgCjc
ENV REDMINE_SQL_USER redmine
ENV REDMINE_SQL_PASS FU7upvs1XPgHEtuyvUIRRcs
ENV REDMINE_SQL_DATABASE redmine

RUN echo "Asia/Tokyo" > /etc/timezone \
 && dpkg-reconfigure -f noninteractive tzdata \
 && apt-get update 
 && apt-get -y upgrade \
 && apt-get -y dist-upgrade \
 && apt-get install -y software-properties-common apache2 libapache2-mod-passenger wget git subversion imagemagick bundler ruby-nokogiri build-essential ruby-dev ruby-thor ruby-rmagick \
 && apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db \
 && add-apt-repository 'deb http://ftp.yz.yamagata-u.ac.jp/pub/dbms/mariadb/repo/10.0/ubuntu trusty main' \
 && echo "mariadb-server-10.0 mysql-server/root_password password ${SQL_ROOT_PASS}"  |debconf-set-selections \
 && echo "mariadb-server-10.0 mysql-server/root_password_again password ${SQL_ROOT_PASS}"  |debconf-set-selections \
 && echo "redmine redmine/instances/default/mysql/app-pass password ${REDMINE_SQL_PASS}"  |debconf-set-selections \
 && echo "redmine redmine/instances/default/mysql/admin-pass password ${SQL_ROOT_PASS}"  |debconf-set-selections \
 && echo "redmine redmine/instances/default/mysql/admin-user string root"  |debconf-set-selections \
 && echo "redmine redmine/instances/default/database-type string mysql"  |debconf-set-selections \
 && echo "redmine redmine/instances/default/default-language string ja"  |debconf-set-selections \
 && echo "redmine redmine/instances/default/db/app-user string ${REDMINE_SQL_USER}"  |debconf-set-selections \
 && echo "redmine redmine/instances/default/mysql/method string unix socket"  |debconf-set-selections \
 && echo "redmine redmine/instances/default/dbconfig-install string true"  |debconf-set-selections \
 && echo "redmine redmine/instances/default/db/dbname string ${REDMINE_SQL_DATABASE}"  |debconf-set-selections \
 && echo "redmine redmine/current-instances string default"  |debconf-set-selections \
 && DEBIAN_FRONTEND=noninteractive  apt-get install -y mariadb-server libmariadbclient-dev \
 && service mysql start \
 && mysql -uroot -p${SQL_ROOT_PASS} -e"create database ${REDMINE_SQL_DATABASE} character set utf8; create user '${REDMINE_SQL_USER}'@'localhost' identified by '${REDMINE_SQL_PASS}'; grant all privileges on ${REDMINE_SQL_DATABASE}.* to '${REDMINE_SQL_USER}'@'localhost';" \
 && DEBIAN_FRONTEND=noninteractive  apt-get install -y redmine redmine-mysql \
 && chown -R www-data:www-data /usr/share/redmine \
 && echo ServerName $HOSTNAME > /etc/apache2/conf-available/fqdn.conf \
 && a2enconf fqdn \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ADD ./Gemfile.local /usr/share/redmine/Gemfile.local
WORKDIR /usr/share/redmine/
RUN git clone https://github.com/rkallensee/redmine-google-analytics-plugin.git /usr/share/redmine/plugins/redmine-google-analytics-plugin \
 && git clone https://github.com/taktos/redmine_holidays_plugin.git /usr/share/redmine/plugins/redmine_holidays_plugin \
 && git clone https://github.com/ryu00026/redmine_ical.git /usr/share/redmine/plugins/redmine_ical \
 && git clone https://github.com/twinslash/redmine_omniauth_google.git /usr/share/redmine/plugins/redmine_omniauth_google \
 && git clone git://github.com/backlogs/redmine_backlogs.git /usr/share/redmine/plugins/redmine_backlogs \
 && git clone https://github.com/Eyepea/redmine_auto_assigned_user.git /usr/share/redmine/plugins/redmine_auto_assigned_user \
 && git clone https://github.com/koppen/redmine_github_hook.git /usr/share/redmine/plugins/edmine_github_hook \
 && git clone https://github.com/bearmini/redmine_wiki_unc.git /usr/share/redmine/plugins/redmine_wiki_unc \
 && wget https://bitbucket.org/tkusukawa/redmine_work_time/downloads/redmine_work_time-0.2.16.zip \
 && unzip redmine_work_time-0.2.16.zip -d /usr/share/redmine/plugins/ \
 && rm redmine_work_time-0.2.16.zip \
 && cat plugins/redmine_backlogs/Gemfile | grep holidays > plugins/redmine_holidays_plugin/Gemfile \
 && git clone git://github.com/makotokw/redmine-theme-gitmike.git public/themes/gitmike \
 && git clone git://github.com/farend/redmine_theme_farend_fancy.git public/themes/farend_fancy \
 && find -name Gemfile  | xargs sed -i -e "s/http:\/\/rubygems.org/https:\/\/rubygems.org/g" \
 && service mysql start \
 && bundle install \
 && bundle exec rake redmine:plugins:migrate RAILS_ENV=production \
 && chown -R www-data:www-data plugins/

ADD ./000-default.conf /etc/apache2/sites-available/000-default.conf
ADD ./passenger.conf /etc/apache2/mods-enabled/passenger.conf
ADD ./cmd.sh /root/cmd.sh

RUN chmod +x /root/cmd.sh

EXPOSE 80
ENTRYPOINT ["/root/cmd.sh"]


