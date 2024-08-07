### PhotonBBS Container
###
### Building: docker volume create appdata
###           docker image build -t photonbbs .
###
### Execution: docker container run -ti --net host --device=/dev/tty0 \
###                   -v appdata:/appdata:rw --privileged -p 23:23 photonbbs
###
### TODO: Figure out why libwrap isn't working in the container.
###
### Note: This container accepts parameters, pass 'bash' to start the container with a shell.
###

FROM rockylinux:9
WORKDIR /

RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RUN yum -y install tcp_wrappers xinetd telnet-server cronie perl git fail2ban rsyslog nano rsyslog-mmjsonparse bind-utils procps
RUN yum -y install http://download1.rpmfusion.org/free/el/updates/6/i386/dosemu-1.4.0.8-15.20130205git.el6.i686.rpm

COPY appdeploy /
COPY startscript /

EXPOSE 23

RUN bash /appdeploy

ENTRYPOINT [ "/usr/sbin/init" ]
CMD []
