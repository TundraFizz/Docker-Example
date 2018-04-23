# Docker-Example

docker images

docker container ls
docker container ls -aq
docker container ls --all

docker load -i image-name.tar
docker import image-name.tar aaaaaaa

docker build -t image-name .
docker save image-name > image-name.tar

docker tag image-name tundrafizz/image-name
docker push tundrafizz/image-name

docker run -p 80:9001 image-name
docker run -d -p 80:9001 image-name

Delete one image
docker rmi IMAGE_ID

Delete all images
docker images -q | xargs docker rmi -f

Stop all containers
docker stop $(docker ps -aq)

Delete all containers
docker rm -f $(docker ps -aq)

You can only deploy stacks on a swarm, so you will need to run `docker swarm init` or `docker swarm join` before executing the below command
`docker stack deploy -c docker-stack.yml yoloswag`

docker service ls
docker service ls -q
docker service rm djveoeogo09m
docker service rm $(docker service ls -q)

docker-machine ls
