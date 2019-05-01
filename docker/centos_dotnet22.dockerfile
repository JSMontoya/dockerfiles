# Copyright (c) 2012-2018 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

FROM registry.centos.org/che-stacks/centos-stack-base:latest

RUN sudo yum -y update && \
    sudo yum -y install centos-release-dotnet && \
    sudo yum -y install rh-dotnet22 && \
    sudo yum clean all && \
    ls /opt/rh/rh-dotnet22/root/usr/lib64/dotnet/sdk/ && \
    sudo ln -s /opt/rh/rh-dotnet22/root/usr/lib64/dotnet/sdk/2.2.105/Sdks/Microsoft.NET.Sdk/tools/netcoreapp1.0 /opt/rh/rh-dotnet22/root/usr/lib64/dotnet/sdk/2.2.105/Sdks/Microsoft.NET.Sdk/tools/net46

ENV PATH=/opt/rh/rh-dotnet22/root/usr/bin:/opt/rh/rh-dotnet22/root/usr/sbin${PATH:+:${PATH}}
ENV CPATH=/opt/rh/rh-dotnet22/root/usr/include${CPATH:+:${CPATH}}
ENV LD_LIBRARY_PATH=/opt/rh/rh-dotnet22/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV MANPATH=/opt/rh/rh-dotnet22/root/usr/share/man:${MANPATH:-}
ENV PKG_CONFIG_PATH=/opt/rh/rh-dotnet22/root/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}
ENV PYTHONPATH=/opt/rh/rh-dotnet22/root${PYTHONPATH:+:${PYTHONPATH}}
ENV XDG_DATA_DIRS=/opt/rh/rh-dotnet22/root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true

RUN sudo yum -y install rh-nodejs8 && \
    sudo yum clean all && \
    sudo ln -s /opt/rh/rh-nodejs8/root/usr/bin/node /usr/local/bin/nodejs 
ENV PATH=/opt/rh/rh-nodejs8/root/usr/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/opt/rh/rh-nodejs8/root/usr/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV PYTHONPATH=/opt/rh/rh-nodejs8/root/usr/lib/python2.7/site-packages${PYTHONPATH:+:${PYTHONPATH}}
ENV MANPATH=/opt/rh/rh-nodejs8/root/usr/share/man:$MANPATH

ARG OMNISHARP_CLIENT_VERSION=7.1.3
ARG OMNISHARP_SERVER_VERSION=1.23.1
RUN mkdir -p ${HOME}/che/ls-csharp && \
   cd ${HOME}/che/ls-csharp && \
   npm install omnisharp-client@${OMNISHARP_CLIENT_VERSION} && \
   echo -e "#!/bin/sh\nnodejs ${HOME}/che/ls-csharp/node_modules/omnisharp-client/languageserver/server.js\n" > ./launch.sh && \
   mkdir -p ${HOME}/che/ls-csharp/node_modules/omnisharp-client/omnisharp-linux-x64 && \
   curl -sSL https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v${OMNISHARP_SERVER_VERSION}/omnisharp-linux-x64.tar.gz -o ${HOME}/che/ls-csharp/node_modules/omnisharp-client/omnisharp-linux-x64/omnisharp-linux-x64.tar.gz && \
   tar -xzf ${HOME}/che/ls-csharp/node_modules/omnisharp-client/omnisharp-linux-x64/omnisharp-linux-x64.tar.gz -C ${HOME}/che/ls-csharp/node_modules/omnisharp-client/omnisharp-linux-x64 && \
   rm ${HOME}/che/ls-csharp/node_modules/omnisharp-client/omnisharp-linux-x64/omnisharp-linux-x64.tar.gz && \
   echo -e "v${OMNISHARP_SERVER_VERSION}" > ${HOME}/che/ls-csharp/node_modules/omnisharp-client/omnisharp-linux-x64/.version && \
   chmod +x ./launch.sh

ARG OC_VERSION=3.9.38

# Env for installing C# lang server
ENV OMISHARP_VERSION="1.31.1"
ENV OMNISHARP_DOWNLOAD_URL="https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v${OMISHARP_VERSION}/omnisharp-linux-x64.tar.gz"
ENV CSHARP_LS_DIR=${HOME}/che/ls-csharp

# Install OpenShift CLI
RUN sudo yum update -y -d 1 && \
    sudo yum install -y -d 1 \
      tar \
      wget && \
    sudo wget -qO- "https://mirror.openshift.com/pub/openshift-v3/clients/${OC_VERSION}/linux/oc.tar.gz" | sudo tar xvz -C /usr/local/bin && \
    sudo yum clean all && \
    sudo rm -rf /tmp/* /var/cache/yum

# Install C# lang server
RUN cd ${CSHARP_LS_DIR} && wget -q https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v1.31.1/omnisharp-linux-x64.tar.gz && \
    tar -xvf omnisharp-linux-x64.tar.gz --strip 1 && \
    sudo chgrp -R 0 ${HOME} && \
    sudo chmod -R g+rwX ${HOME}
EXPOSE 5000 9000

# The following lines are needed to set the correct locale after `yum update`
# c.f. https://github.com/CentOS/sig-cloud-instance-images/issues/71
RUN sudo localedef -i en_US -f UTF-8 C.UTF-8
ENV LANG="C.UTF-8"
