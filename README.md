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
| `docker push tundrafizz/image-name`       | Push an image to Docker's online repository |

#### Containers
| Command                         | Description                           |
| ------------------------------- | ------------------------------------- |
| `docker container ls`           | List currently running containers     |
| `docker container ls -aq`       | List all containers, only showing IDs |
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
| Command                                     | Description                               |
| ------------------------------------------- | ----------------------------------------- |
| `docker stack deploy -c docker.yml sample`  | Create services from a stack/compose file |
| `docker node ls`                            | List all workers/managers in the swarm    |
| `docker node ps $(docker node ls -q)`       | List all tasks across all nodes           |
| `docker service ls`                         | List all services in the swarm            |
| `docker service ls -q`                      | List all services in the swarm (only IDs) |
| `docker service ps NAME`                    | Check detailed status of a service        |
| `docker service rm ID`                      | Remove a particular service               |
| `docker service rm $(docker service ls -q)` | Remove all services                       |

Create a service manually
`docker service create --replicas 4 -p 80:9001 --name sample tundrafizz/web-test`

#### Services
| Command                                     | Description                               |
| ------------------------------------------- | ----------------------------------------- |
| `docker-machine ls`                         | I'm not sure what this is for yet         |

#### Docker file template
```
FROM node:carbon
WORKDIR /usr/src/app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 9001
CMD ["npm", "start"]
```
