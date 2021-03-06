version: '2'

volumes:

  session:

  solodev-client:
    external: false
    driver: pxd
    driver_opts:
      repl: '2'
      size: '50'
      shared: true

  solodev-mysql:
    external: false
    driver: pxd
    driver_opts:
      repl: '2'
      size: '10'

  solodev-mongo:
    external: false
    driver: pxd
    driver_opts:
      repl: '2'
      size: '10'

services:

  php-fpm-lb:
    restart: always
    tty: true
    image: rancher/load-balancer-service
    expose:
      - 9000/tcp
    labels:
      io.rancher.container.agent.role: environmentAdmin
      io.rancher.container.create_agent: 'true'
    links:
      - php-fpm
    stdin_open: true

  php-fpm:
    image: solodev/wcms
    tty: true
    environment:
      DB_HOST: mysql
      DB_USER: '${MYSQL_USER}'
      DB_PASSWORD: '${MYSQL_PASSWORD}'
      DB_NAME: '${MYSQL_DATABASE}'
      MONGO_HOST: mongo
      SOLODEV_USER: '${SOLODEV_USER}'
      SOLODEV_PASSWORD: '${SOLODEV_PASSWORD}'
    labels:
      io.rancher.container.network: true
      io.rancher.container.pull_image: always
    volumes:
      - solodev-client:/var/www/Solodev/clients/solodev
      - session:/var/lib/php/session
    links:
      - mysql
      - mongo
    depends_on:
      - mysql
    restart: always

  apache2-lb:
    restart: always
    tty: true
    image: rancher/load-balancer-service
    ports:
      - ${SOLODEV_PORT}:80
    labels:
      io.rancher.container.agent.role: environmentAdmin
      io.rancher.container.create_agent: 'true'
    links:
      - apache2
    stdin_open: true

  apache2: 
    image: solodev/wcms-apache
    labels:
      io.rancher.container.network: true
      io.rancher.container.pull_image: always
    volumes:
      - solodev-client:/var/www/Solodev/clients/solodev
    links:
      - php-fpm-lb:php-fpm
    entrypoint: /usr/local/apache/conf/wait-for-it.sh php-fpm:9000 -t 60 --
    command: ["httpd-foreground"]
    restart: always

  mysql:
    image: mysql:5.7.20
    command: --sql_mode=""
    environment:
      MYSQL_DATABASE: '${MYSQL_DATABASE}'
      MYSQL_PASSWORD: '${MYSQL_PASSWORD}'
      MYSQL_ROOT_PASSWORD: '${MYSQL_ROOT_PASSWORD}'
      MYSQL_USER: '${MYSQL_USER}'
    restart: always
    volumes:
      - solodev-mysql:/var/lib/mysql:rw

  mongo:
    image: 'mongo:3.0'
    environment:
      MONGO_INITDB_ROOT_USERNAME: '${MYSQL_USER}'
      MONGO_INITDB_ROOT_PASSWORD: '${MYSQL_ROOT_PASSWORD}'
    volumes:
      - solodev-mongo:/data