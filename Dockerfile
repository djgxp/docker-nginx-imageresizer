FROM centos:7
MAINTAINER gtrebos

# Install Nginx
ADD conf/nginx.repo /etc/yum.repos.d/

RUN cd /tmp && \
  curl -O http://nginx.org/keys/nginx_signing.key && \
  rpm --import nginx_signing.key

RUN yum -y upgrade
RUN yum -y update; yum clean all
RUN yum -y install nginx nginx-module-image-filter gd gd-devel
RUN yum -y install bash-completion \
                   curl \
                   openssh-clients \
                   openssh-server \
                   vim-enhanced \
                   sudo \

# Clean up YUM when done.
RUN yum clean -y all

# Configure nginx site
RUN rm /etc/nginx/conf.d/default.conf
COPY conf/nginx.conf /etc/nginx/conf.d/nginx.conf
RUN sed -i '1s/^/load_module\ \"modules\/ngx_http_image_filter_module.so\"\;/' /etc/nginx/nginx.conf

# Deal with ssh
COPY ssh_keys/id_rsa /root/.ssh/id_rsa
COPY ssh_keys/id_rsa.pub /root/.ssh/id_rsa.pub
RUN echo "IdentityFile /root/.ssh/id_rsa" > /root/.ssh/config

# set root password
RUN echo 'root:password' | chpasswd
RUN sed -i 's/\#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/\#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config

# generate server keys
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN echo 'SSHD: ALL' >> /etc/hosts.allow

EXPOSE 80

ADD init.sh /init.sh
RUN chmod +x /init.sh
CMD /init.sh