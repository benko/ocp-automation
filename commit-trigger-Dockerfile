FROM registry.redhat.io/openshift4/ose-cli:latest

COPY commit-trigger.sh /usr/local/bin/

RUN chmod 755 /usr/local/bin/commit-trigger.sh && \
	yum -y install git && yum clean all && rm -rf /var/cache/yum

USER 1001

ENV	CLUSTER= \
	PROJECT= \
	TOKEN_SECRET_FILE= \
	BUILDCONFIG=

LABEL description 'Checks that remote and last build's commit ID are the same, or starts a new build otherwise. Requires BUILDCONFIG to be set in env.'

MAINTAINER gbremec@redhat.com

CMD /usr/local/bin/commit-trigger.sh
