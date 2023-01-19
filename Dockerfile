FROM ubuntu:22.04

# Setup environment
RUN apt-get update && apt-get install -y \
    build-essential \
    curl  \
    git \
    openssh-server  \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install n and LTS node
WORKDIR /root
RUN git clone https://github.com/visionmedia/n.git \
    && cd n \
    && make install \
    && n lts


# Setup nodester user
RUN groupadd nodester && useradd -d /var/nodester -c "nodester" -g nodester -m -r -s /bin/bash nodester
RUN echo "nodester:password" | chpasswd
COPY nodester_sudoers /etc/sudoers.d/nodester_sudoers
WORKDIR /var/nodester

# setup SSH
RUN mkdir ~nodester/.ssh \
COPY authorized_keys ~nodester/.ssh/authorized_keys
RUN chown -R nodester:nodester ~nodester/.ssh/ \
    && chmod go-rwx ~nodester/.ssh/authorized_keys \
    && ssh-keygen -A \
    && service ssh start
EXPOSE 22

# setup nodester
USER nodester
COPY . nodester
WORKDIR /var/nodester/nodester
COPY example_config.js config.js
USER root
RUN chown -R nodester:nodester . \
    && chown -R root:root proxy \
    && cp scripts/git-shell-enforce-directory /usr/local/bin \
    && chmod +x /usr/local/bin/git-shell-enforce-directory
USER nodester
RUN npm install
EXPOSE 4001

#USER root
#CMD ["/usr/sbin/sshd","-D"]
USER nodester
ENTRYPOINT ["node"]
CMD ["app"]


