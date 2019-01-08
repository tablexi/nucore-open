FROM ruby:2.4.1

# Install NodeJS based on https://github.com/nodesource/distributions#installation-instructions
RUN apt-get update
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash # Installs the node repository
RUN apt-get install --yes nodejs # Actually install NODEJS

# Cleanup
RUN apt-get autoremove -y

RUN mkdir -p /root/.ssh
COPY ./ssh/id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
# store the ssh key so that it doesn't say "Are you sure you want to continue connecting?"
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

WORKDIR /app
ENV BUNDLE_PATH /gems

ENTRYPOINT ["./docker-entrypoint.sh"]
