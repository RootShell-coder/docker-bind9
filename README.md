# docker bind9

[![bind9](https://github.com/RootShell-coder/docker-bind9/actions/workflows/docker_build.yml/badge.svg?branch=master)](https://github.com/RootShell-coder/docker-bind9/actions/workflows/docker_build.yml)

Split horizon DNS with bind9 and auto update named.root

`wget https://raw.githubusercontent.com/RootShell-coder/docker-bind9/master/docker-compose.yml`

```yml
version: '3.9'

networks:
  named:
    name: named
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.18.0.0/24
          gateway: 172.18.0.1

volumes:
  bind_conf:
    name: bind_conf

services:
  bind:
    image: rootshellcoder/bind9
    networks:
      - named
    volumes:
      - bind_conf:/etc/bind
    environment:
      - TZ=Europe/Moscow
      - LOCALE=ru_RU
      - CRON_HINT_FILE='https://www.internic.net/domain/named.root'
      - CRON_HINT_TIME='0 1 1 * * *'
    ports:
      - 8080:8080/tcp
      - 953:953/tcp
      - 172.18.0.1:53:53/tcp
      - 172.18.0.1:53:53/udp
```

`docker compose up -d`

`docker ps`

```bash
CONTAINER ID   IMAGE     COMMAND        CREATED         STATUS         PORTS                                                                                                                            NAMES
5e3ac0fffef2   bind      "entrypoint"   8 seconds ago   Up 7 seconds   0.0.0.0:953->953/tcp, :::953->953/tcp, 172.18.0.1:53->53/tcp, 172.18.0.1:53->53/udp, 0.0.0.0:8080->8080/tcp, :::8080->8080/tcp   bind-bind-1
```

## external

`dig @172.18.0.2 A www.example.com`

```bash
; <<>> DiG 9.16.33-RH <<>> @172.18.0.2 A www.example.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62115
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 952b3f0fc7790d800100000063e2e88b5d94b21e949f3fa0 (good)
;; QUESTION SECTION:
;www.example.com.               IN      A

;; ANSWER SECTION:
www.example.com.        600     IN      A       172.18.0.2

;; Query time: 1 msec
;; SERVER: 172.18.0.2#53(172.18.0.2)
;; WHEN: Wed Feb 08 03:10:51 MSK 2023
;; MSG SIZE  rcvd: 88

```

## internal

`docker exec -ti 5e dig @127.0.0.1 A www.example.com`

```bash
; <<>> DiG 9.18.11 <<>> @127.0.0.1 A www.example.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18309
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 4d85bbef62daa5060100000063e2e77396f1603a0441514d (good)
;; QUESTION SECTION:
;www.example.com.               IN      A

;; ANSWER SECTION:
www.example.com.        600     IN      A       127.0.0.1

;; Query time: 0 msec
;; SERVER: 127.0.0.1#53(127.0.0.1) (UDP)
;; WHEN: Wed Feb 08 03:06:11 MSK 2023
;; MSG SIZE  rcvd: 88
```
