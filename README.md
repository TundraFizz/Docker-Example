# Docker-Example

docker images

docker container ls
docker container ls -aq
docker container ls --all

docker load -i image-name.tar
docker import image-name.tar aaaaaaa

docker build -t image-name .
docker save image-name > image-name.tar

docker run -p 80:9001 image-name
docker run -d -p 80:9001 image-name

docker rmi IMAGE_ID
docker rm -f $(docker ps -a -q)
docker images -q | xargs docker rmi -f
docker stop $(docker ps -a -q)
