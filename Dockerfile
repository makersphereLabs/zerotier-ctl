FROM debian:8.6
MAINTAINER Makersphere Labs <opensource@makersphere.org>

ENV ZEROTIER_VERSION 1.1.14

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
clang \
curl \
git \
libsqlite3-dev \
make \
ruby-ronn \
sqlite3 \
&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/source \
&& cd /app/source && git clone https://github.com/zerotier/ZeroTierOne.git \
&& cd /app/source/ZeroTierOne && git checkout tags/$ZEROTIER_VERSION \
&& cd /app/source/ZeroTierOne \
&& make ZT_ENABLE_NETWORK_CONTROLLER=1 \
&& make install \
&& rm -rf /app/source \
&& apt-get remove -y \
clang \
git \
make

COPY ./run/start.sh /app/start.sh
COPY ./src/bin/app.sh /usr/sbin/zerotier-ctl

RUN chmod +x /app/start.sh \
&& chmod +x /usr/sbin/zerotier-ctl \
&& ln /usr/sbin/zerotier-ctl /var/lib/zerotier-one/zerotier-ctl

WORKDIR /var/lib/zerotier-one

EXPOSE 9993/udp
CMD ["/app/start.sh"]
