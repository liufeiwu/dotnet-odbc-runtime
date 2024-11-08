FROM docker.rainbond.cc/library/ubuntu:14.04

RUN apt update && \
    apt install -y wget build-essential curl wget libicu-dev make g++ libssl-dev openssl vim locate language-pack-zh-hans language-pack-zh-hant unixodbc-dev&& \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* 

# install dotnet sdk
# doc => https://dotnet.microsoft.com/zh-cn/download/dotnet/thank-you/sdk-3.1.426-linux-x64-binaries
ENV DOTNET_ROOT=/opt/dotnet
ENV PATH=$PATH:$DOTNET_ROOT
RUN wget https://download.visualstudio.microsoft.com/download/pr/e89c4f00-5cbb-4810-897d-f5300165ee60/027ace0fdcfb834ae0a13469f0b1a4c8/dotnet-sdk-3.1.426-linux-x64.tar.gz && \
    mkdir -p /opt/dotnet && tar zxf dotnet-sdk-3.1.426-linux-x64.tar.gz -C /opt/dotnet && \
    rm -rf dotnet-sdk-3.1.426-linux-x64.tar.gz 

# install character set
# doc => https://zhuanlan.zhihu.com/p/165961076
RUN cd /usr/share/locales  && \
    ./install-language-pack zh_CN && \
    ./install-language-pack en_US && \
    echo "" >> /etc/environment && \
    echo "# character set" >> /etc/environment && \
    echo "export LANG=zh_CN.UTF-8" >> /etc/environment && \
    echo "export LANGUAGE=en_US:en" >> /etc/environment && \
    echo 'export LC_CTYPE="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_NUMERIC="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_TIME="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_COLLATE="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_MONETARY="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_MESSAGES="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_PAPER="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_NAME="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_ADDRESS="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_TELEPHONE="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_MEASUREMENT="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_IDENTIFICATION="zh_CN.UTF-8"' >> /etc/environment && \
    echo 'export LC_ALL=zh_CN.UTF-8' >> /etc/environment && \
    cd

# copy files
COPY root /

# install odbc 11
# doc => https://blog.csdn.net/code_my_life/article/details/46609947 && https://www.cnblogs.com/itschen/p/14831048.html
RUN cd /odbc && \
    cp -rf msodbcsql-11.0.2270.0 msodbcsql-11.0.2270.0.bak && \
    tar zxvf RedHat6-msodbcsql-11.0.2270.0.tar.gz && \
    cp unixODBC-2.3.12.tar.gz ./msodbcsql-11.0.2270.0/ && \
    cp -rf msodbcsql-11.0.2270.0.bak/build_dm.sh msodbcsql-11.0.2270.0/ && \
    cp -rf msodbcsql-11.0.2270.0.bak/install.sh msodbcsql-11.0.2270.0/ && \
    cd msodbcsql-11.0.2270.0/ && \
    chmod +x build_dm.sh && \
    chmod +x install.sh && \
    ./build_dm.sh --download-url=file://unixODBC-2.3.12.tar.gz && \
    cd /tmp/unixODBC.11/unixODBC-2.3.12 && \
    ./configure && \
    make && \
    make install && \
    odbc_config --odbcinstini && \
    cd /odbc/msodbcsql-11.0.2270.0 && \
    cd /lib/x86_64-linux-gnu/ && \
    ln -s libssl.so.1.0.0 libssl.so.10 && \
    ln -s libcrypto.so.1.0.0 libcrypto.so.10 && \
    /odbc/msodbcsql-11.0.2270.0 && \
    ldd lib64/libmsodbcsql-11.0.so.2270.0 | grep not && \
    cd

CMD [ "BASH" ]