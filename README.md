# SSHRP

A simple SSH reverse proxy, forwarding connection depending username


### How to use

create config folder

```
~ mkdir config
~ mkdir config/users
```

then create as many users as you want

exemple for toto user

```
~ mkdir config/users/toto
~ cp ~/.ssh/id_rsa.pub config/users/toto/authorized_keys
~ ssh-keygen -t rsa -f config/users/toto/id_rsa
```

then specify destination server

```
~ cat config/users/toto/config.json
{
    "destination_host": "exemple.com",
    "destination_user": "my-remote-user",
    "desitnation_port": 22
}
```

then

```
docker-compose up -d
```