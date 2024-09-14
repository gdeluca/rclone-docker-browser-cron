# rclone-docker-browser-cron
docker images to handle google drive sync using rclone bisync on linux

Steps:

1- install and setup rclone on host

$ rclone config

2- build or use published image

$ docker build -t rclone-browser-runtime .

3- running docker container

docker run -it \
    --name rclone-browser-container \
    --restart unless-stopped \
    -e DISPLAY=$DISPLAY \
    -e REMOTE_PATH="drive:" \
    -v /usr/bin/rclone:/usr/bin/rclone \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/.config/rclone:/root/.config/rclone \
    -v $HOME/gdrive:/root/gdrive \
    rclone-browser-runtime

or from publihed package
 docker run -it \
    --name rclone-browser-container \
    --restart unless-stopped \
    -e DISPLAY=$DISPLAY \
    -e REMOTE_PATH="drive:/sistema" \
    -v /usr/bin/rclone:/usr/bin/rclone \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/.config/rclone:/root/.config/rclone \
    -v $HOME/gdrive:/root/gdrive \
    ghcr.io/gdeluca/rclone-browser-rumtime:1.0
    
4- 
change folder permissions: 
sudo chown -R $(id -u):$(id -g) $HOME/gdrive

browser : 
docker exec -it rclone-browser-container rclone-browser

console: 
docker exec -it rclone-browser-container /bin/sh

stop: 
docker stop rclone-browser-container

replication folder mounted at $HOME/gdrive will be created


note:this is based on experimental rclone bisync

