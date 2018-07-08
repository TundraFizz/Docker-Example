#### Images
| Command                                   | Description                                 |
| ----------------------------------------- | ------------------------------------------- |
| `docker images`                           | List all available images                   |
| `docker build -t image-name .`            | Create image from source code               |
| `docker save image-name > image-name.tar` | Save an image to a .tar                     |
| `docker load -i image-name.tar`           | Load an image from a .tar                   |
| `docker run -p 80:9001 image-name`        | Run image in terminal (useful for testing)  |
| `docker tag image-name repo:tag`          | Set an image's repository and tag           |
| `docker rmi IMAGE_ID`                     | Delete a particular image                   |
| `docker rmi -f $(docker images -q)`       | Delete all images                           |
| `docker login`                            | You need to login before pushing            |
| `docker push tundrafizz/image-name`       | Push an image to Docker's online repository |

#### Containers
| Command                         | Description                           |
| ------------------------------- | ------------------------------------- |
| `docker container ls`           | List currently running containers     |
| `docker container ls -aq`       | List all containers, only showing IDs |
| `docker restart CONTAINER_ID`   | Restart a container                   |
| `docker stop $(docker ps -aq)`  | Stop all containers                   |
| `docker rm -f $(docker ps -aq)` | Delete all containers                 |

#### Swarms
| Command                           | Description                                |
| --------------------------------- | ------------------------------------------ |
| `docker swarm init`               | Initialize a Docker swarm                  |
| `docker swarm join TOKEN`         | Join a Docker swarm                        |
| `docker swarm join-token worker`  | Display the token for joining as a worker  |
| `docker swarm join-token manager` | Display the token for joining as a manager |

#### Services
| Command                                             | Description                               |
| --------------------------------------------------- | ----------------------------------------- |
| `docker stack deploy -c docker-compose.yml sample`  | Create services from a stack/compose file |
| `docker node ls`                                    | List all workers/managers in the swarm    |
| `docker node ps $(docker node ls -q)`               | List all tasks across all nodes           |
| `docker service ls`                                 | List all services in the swarm            |
| `docker service ls -q`                              | List all services in the swarm (only IDs) |
| `docker service ps NAME`                            | Check detailed status of a service        |
| `docker service rm ID`                              | Remove a particular service               |
| `docker service rm $(docker service ls -q)`         | Remove all services                       |

Create a container from image manually
`docker run --name=sample -d tundrafizz/sample-app`

#### Other notes [1]

`sudo yum -y install epel-release`
`sudo curl -sL https://rpm.nodesource.com/setup_8.x | sudo bash -`
`sudo yum -y install nodejs`
`sudo npm i -g nodemon`

`docker run -it -d -p 8080:8080 -e HOST=54.202.110.238 -v /var/run/docker.sock:/var/run/docker.sock docker.io/dockersamples/visualizer:latest`

SSH into a docker container
`docker exec -it 66f1859e1583 bash`
`docker exec -it 66f1859e1583 /bin/sh`

Copy a file from a container to the host and vice versa
`docker cp <container>:/path/to/file.ext .`
`docker cp file.ext <container>:/path/to/file.ext`

`docker exec -it $(docker container ls | grep nginx | grep -Eo '^[^ ]+') bash`
`docker exec -it $(docker container ls | grep nginx | grep -Eo '^[^ ]+') nginx -s reload`

#### Sample
`script-centos-user.sh` to set up the environment for Docker
`git clone https://github.com/TundraFizz/Docker-Example`
`cd Docker-Example`
`docker build -t sample-app sample-app`
`bash mollusk.sh nconf -c sample-app -s ip`
`bash mollusk.sh nconf -c phpmyadmin -s ip -p 9000`
`docker swarm init`
`docker stack deploy -c docker-compose.yml sample`

