# rclone-docker-browser-cron
Docker container to handle google drive synchonization on linux using rclone, bisync and cron on linux

Steps
1- install and setup rclone on host

<code>
rclone config
</code>

Option 1. Setup from published image:

<code>
 docker run -it \
    --name rclone-browser-container \
    --restart unless-stopped \
    -e DISPLAY=$DISPLAY \
    -e REMOTE_PATH="drive:" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/.config/rclone:/root/.config/rclone \
    -v $HOME/gdrive:/root/gdrive \
    ghcr.io/gdeluca/rclone-browser-runtime:1.0
</code>

Option 2. Setup from sources:

1- clone repo
2-
<code>
docker build -t rclone-browser-runtime .
</code>

3- Running docker container
<code>
docker run -it \
    --name rclone-browser-container \
    --restart unless-stopped \
    -e DISPLAY=$DISPLAY \
    -e REMOTE_PATH="drive:" \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/.config/rclone:/root/.config/rclone \
    -v $HOME/gdrive:/root/gdrive \
    rclone-browser-runtime
</code>
 
change folder permissions on host: 

<code>
sudo chown -R $(id -u):$(id -g) $HOME/gdrive
</code>

To run docker browser:
<code>
xhost +local:root && docker exec -it rclone-browser-container rclone-browser
</code>

To run docker console: 
<code>
docker exec -it rclone-browser-container /bin/sh
</code>

To stop docker container: 
<code>
docker stop rclone-browser-container && docker rm rclone-browser-container
</code>

note that rclone bisync is still experimental

