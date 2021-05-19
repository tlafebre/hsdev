FROM centos:7

USER root

ENV LANG="en_US.UTF-8"

RUN ln -nsf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

WORKDIR /etc/
RUN echo "proxy=http://host.docker.internal:3128" >> yum.conf

RUN yum install -y git            \
                   ncurses        \
                   ncurses-devel  \
                   ncurses-libs   \
                   ncurses-static \
                   ncurses-term   \
                   screen         \
                   sudo           \
                   tree           \
                   vim

RUN yum clean all # makes sense for squashed builds

WORKDIR /etc/
RUN sed -i -e "/^%wheel/ d"         sudoers # remove PASSWORD
RUN sed -i -e "s/^# %wheel/%wheel/" sudoers # activate NOPASSWORD

RUN adduser --home-dir /home/tjeerd tjeerd
RUN usermod -a -G wheel tjeerd

RUN chmod g+wxs .

WORKDIR /home/tjeerd/
COPY run/res/home/ .
RUN echo "hardstatus off" >> .screenrc

WORKDIR /home/tjeerd/
COPY res/home/first_run           .first_run
COPY res/home/run                 .run
COPY res/home/start               .start
COPY res/deploy/config.yaml       /home/tjeerd/.stack/
COPY res/deploy/stack.yaml        /home/tjeerd/.stack/global-project/

RUN chown tjeerd.tjeerd -R /home/tjeerd

USER tjeerd

run mkdir -p /home/tjeerd/.stack 

WORKDIR /home/tjeerd

RUN curl -sSL https://get.haskellstack.org/ | sh

RUN stack setup
RUN stack ghci

RUN sed -i '$a alias ghci="stack ghci --verbosity WARN"' /home/tjeerd/.bash_profile

WORKDIR /home/tjeerd

RUN rm -rf /home/tjeerd/tmp/

CMD ./.start
