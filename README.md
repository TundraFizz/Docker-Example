#### Docker Example

#### Quick-Start

```
1. Run the setup which also downloads mollusk.sh and then reboots the system
bash <(curl -Ls https://goo.gl/p22yXn)

2. Generate a default docker-compose file
bash mollusk.sh compose

3. Build your Docker images
docker build -t sample-app sample-app

4. Modify the docker-compose.yml file to include your images

5. Initialize Docker Swarm
docker swarm init

6. Deploy the stack
docker stack deploy -c docker-compose.yml sample

7. Generate SSL certificates and NGINX config files
bash mollusk.sh ssl -d mudki.ps -se sample-app -st sample -s

Create stuff:
logs
nginx_conf.d
single_files => 5 files
```

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

#### Misc
| Command                                                          | Description                                |
| ---------------------------------------------------------------- | ------------------------------------------ |
| `docker service logs SERVICE_NAME -f`                            | Displays logs of a given service           |
| `find /var/lib/docker/containers/ -type f -name "*.log" -delete` | Deletes all log files                      |
| `docker exec -it CONTAINER_ID bash`                              | SSH into a container                       |
| `docker cp file.ext CONTAINER_ID:/path/to/file.ext`              | Copy a file from the host into a container |
| `docker cp CONTAINER_ID:/path/to/file.ext .`                     | Copy a file from a container into the host |
| `docker run --name=sample -d tundrafizz/sample-app`              | Create a container from image manually     |

#### Other notes [1]

SSH into a container with the name "nginx"
`docker exec -it $(docker container ls | grep nginx | grep -Eo '^[^ ]+') bash`

Perform the command "nginx -s reload" in the container with the name "nginx"
`docker exec -it $(docker container ls | grep nginx | grep -Eo '^[^ ]+') nginx -s reload`

`sudo yum -y install epel-release`
`sudo curl -sL https://rpm.nodesource.com/setup_8.x | sudo bash -`
`sudo yum -y install nodejs`
`sudo npm i -g nodemon`

`docker run -it -d -p 8080:8080 -e HOST=54.202.110.238 -v /var/run/docker.sock:/var/run/docker.sock docker.io/dockersamples/visualizer:latest`

