ARG RELEASE
ARG LAUNCHPAD_BUILD_ARCH

# ============== odbc ============================

FROM docker.rainbond.cc/library/ubuntu:14.04 as builder

LABEL org.opencontainers.image.ref.name=ubuntu
LABEL org.opencontainers.image.version=14.04
CMD ["/bin/bash"]

ENV LANG en_US.utf8
RUN apt update && \
    apt install -y curl wget libicu52 make g++ libssl1.0.0 openssl locales unixodbc tzdata && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libc6 libgcc1 libgssapi-krb5-2 libstdc++6 zlib1g && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# copy files
COPY root /root/

# install odbc 11
# doc => https://blog.csdn.net/code_my_life/article/details/46609947 && https://www.cnblogs.com/itschen/p/14831048.html
RUN cd /root/odbc && \
    cp -rf msodbcsql-11.0.2270.0 msodbcsql-11.0.2270.0.bak && \
    tar zxvf RedHat6-msodbcsql-11.0.2270.0.tar.gz && \
    cp unixODBC-2.3.12.tar.gz ./msodbcsql-11.0.2270.0/ && \
    cp -rf msodbcsql-11.0.2270.0.bak/build_dm.sh msodbcsql-11.0.2270.0/ && \
    cp -rf msodbcsql-11.0.2270.0.bak/install.sh msodbcsql-11.0.2270.0/ && \
    cd /root/odbc/msodbcsql-11.0.2270.0/ && \
    chmod +x build_dm.sh && \
    chmod +x install.sh && \
    ./build_dm.sh --download-url=file://unixODBC-2.3.12.tar.gz && \
    cd /tmp/unixODBC.11/unixODBC-2.3.12 && \
    ./configure && make && make install && \
    cd /lib/x86_64-linux-gnu/ && ln -s libssl.so.1.0.0 libssl.so.10 && ln -s libcrypto.so.1.0.0 libcrypto.so.10 && \
    rm -rf /root/odbc
# test => cd /root/odbc/msodbcsql-11.0.2270.0 && ldd lib64/libmsodbcsql-11.0.so.2270.0 | grep not

# ============== final ============================

FROM builder  AS final

# install dotnet
ENV ASPNETCORE_URLS=http://+:80 DOTNET_RUNNING_IN_CONTAINER=true
RUN dotnet_version=3.1.32 && curl -fSL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Runtime/$dotnet_version/dotnet-runtime-$dotnet_version-linux-x64.tar.gz && dotnet_sha512='a1de9bbc3d2e3a4f5f52b7742c678b182a58a724d36232997511e390027044d60144a7e010a29d6ee016ec91f2911daef28ac5712a827fff8bdde73314b7e002' && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - && mkdir -p /usr/share/dotnet && tar -oxzf dotnet.tar.gz -C /usr/share/dotnet && rm dotnet.tar.gz && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet
RUN aspnetcore_version=3.1.32 && curl -fSL --output aspnetcore.tar.gz https://dotnetcli.azureedge.net/dotnet/aspnetcore/Runtime/$aspnetcore_version/aspnetcore-runtime-$aspnetcore_version-linux-x64.tar.gz && aspnetcore_sha512='0aa2aceda3d0b9f6bf02456d4e4b917c221c4f18eff30c8b6418e7514681baa9bb9ccc6b8c78949a92664922db4fb2b2a0dac9da11f775aaef618d9c491bb319' && echo "$aspnetcore_sha512 aspnetcore.tar.gz" | sha512sum -c - && tar -oxzf aspnetcore.tar.gz -C /usr/share/dotnet ./shared/Microsoft.AspNetCore.App && rm aspnetcore.tar.gz

ENV TZ=Asia/Shanghai