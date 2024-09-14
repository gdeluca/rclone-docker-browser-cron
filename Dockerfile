FROM alpine:3.20.3 as build-rclone-browser

RUN apk update && \
    apk --no-cache add --virtual .build-deps \
    wget \
    unzip \
    build-base \
    cmake \
    qt5-qtbase-dev \
    qt5-qtmultimedia-dev \
    qt5-qttools-dev

RUN wget -q https://github.com/kapitainsky/RcloneBrowser/archive/refs/heads/master.zip && \
    unzip master.zip && \
    mv RcloneBrowser-master /tmp/rclonebrowser && \
    cd /tmp/rclonebrowser && \
    sed -i 's/QString::SkipEmptyParts/Qt::SkipEmptyParts/' src/main_window.cpp && \
    sed -i 's/player->start(stream, QProcess::ReadOnly)/player->start(stream, QStringList(), QProcess::ReadOnly)/' src/main_window.cpp && \
    sed -i 's/cmake_minimum_required(VERSION 3.0)/cmake_minimum_required(VERSION 3.5)/' CMakeLists.txt && \
    mkdir /tmp/build && \
    cd /tmp/build && \
    cmake -Wno-dev -DCMAKE_BUILD_TYPE=Release ../rclonebrowser && \
    cmake --build . && \
    cp /tmp/build/build/rclone-browser /usr/bin/ && \
    chmod +x /usr/bin/rclone-browser && \
    rm -rf /tmp/rclonebrowser /tmp/build master.zip

RUN apk del .build-deps && \
    rm -rf /var/cache/apk/* /tmp/*

FROM alpine:3.20.3 as rclone-browser-runtime

RUN apk update && \
    apk --no-cache add \
    fuse \
    x11vnc \
    bash \
    xvfb \
    qt5-qtbase-x11 && \
    rm -rf /var/cache/apk/*

# Copy the RcloneBrowser binary from the build stage
COPY --from=build-rclone-browser /usr/bin/rclone-browser /usr/bin/rclone-browser
RUN chmod +x /usr/bin/rclone-browser

COPY rclone-bisync.sh /usr/bin
RUN chmod +x /usr/bin/rclone-bisync.sh

ENV RCLONE_CONF="/root/.config/rclone/rclone.conf" \
    LOCAL_PATH="/root/gdrive" \
    DISPLAY=:99 \
    QT_X11_NO_MITSHM=1 \
    LIBGL_ALWAYS_SOFTWARE=1

RUN echo "*/1 * * * * /usr/bin/rclone-bisync.sh >> /var/log/rclone-bisync.log 2>&1" >> /etc/crontabs/root

CMD ["sh", "-c", "Xvfb :99 -screen 0 1024x768x24 & x11vnc -display :99 -nopw -forever & crond -f"]

