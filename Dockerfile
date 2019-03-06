FROM debian:stretch-slim
MAINTAINER Rafael Römhild <rafael@roemhild.de>

# Install slapd and requirements
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get \
        install -y --no-install-recommends \
            slapd \
            ldap-utils \
            openssl \
            ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /etc/ldap/ssl /bootstrap

ENV LDAP_DEBUG_LEVEL=256

# ADD run script
COPY ./run.sh /run.sh

# ADD bootstrap files
ADD ./bootstrap /bootstrap

# Initialize LDAP with data
RUN /bin/bash /bootstrap/slapd-init.sh

VOLUME ["/etc/ldap/slapd.d", "/etc/ldap/ssl", "/var/lib/ldap", "/run/slapd"]

EXPOSE 389 636
# Add labels so OpenShift recognises this as an S2I builder image.

LABEL io.k8s.description="S2I builder for openldap." \
      io.k8s.display-name="openldap" \
      io.openshift.expose-services="8888:http" \
      io.openshift.tags="builder,openldap" \
      io.openshift.s2i.scripts-url="image:///opt/app-root/s2i/bin"

# Copy in S2I builder scripts for installing Python packages and copying
# in of notebooks and data files.

COPY s2i /opt/app-root/s2i

USER 1000

# Override command to startup Jupyter notebook. The original is wrapped
# so we can set an environment variable for notebook password.

CMD [ "/opt/app-root/s2i/bin/run" ]

CMD ["/bin/bash", "/run.sh"]
ENTRYPOINT []
