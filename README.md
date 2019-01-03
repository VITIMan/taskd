# Introduction

This is an image description to build a Taskwarrior server. It uses all the 
certificate infrastructure involved.

## Server side

    docker run -d \
        --hostname=taskd-test \
        --name=taskd-test \
        -v /path/to/taskddata:/var/taskd \
        -p 53589:53589  \
        -e PUID=<HOST_USER_ID> \
        -e PGID=<HOST_GROUP_ID> \
        -e TASKD_USER_ORG=organization \
        -e TASKD_USER_FIRST=firstname \
        -e TASKD_USER_LAST=lastname \
        taskd:latest

* **hostname**: Used to generate the certificates, you can change this value if
you want, but keep in mind this value, it is necessary in client side too.
* **volume**: This directory stores the certificates and the data store.
* **PUID**: A user id which can manage docker `id <USER>` to get the id
* **PGID**: A group id which can manage docker `id <USER>` to get the id

The first docker execution generates certificates for server and a first 
user, the basic credentials for the user could be modified.

* **TASKD_USER_ORG**: The organization for client user
* **TASKD_USER_FIRST**: The First Name of the client user 
* **TASKD_USER_LAST**: The Last Name of the client user

## Client side

1. Copy the user certificate files and the CA to your client configuration 
   directory

```
    cp test_test.* ca.cert.pem ~/.task/
```

2. Get your user identification, input this value in `taskd.credentials` config 
later

```
    cat userid.key
```

3. Configure your client directorya with these values

```
    task config taskd.certificate -- ~/.task/<TASKD_USER_FIRST>_<TASKD_USER_LAST>.cert.pem
    task config taskd.key -- ~/.task/<TASKD_USER_FIRST>_<TASKD_USER_LAST>.key.pem
    task config taskd.ca          -- ~/.task/ca.cert.pem
    task config taskd.server      -- <HOSTNAME>:<PORT>
    task config taskd.credentials -- <TASKD_USER_ORG>/<TASKD_USER_FIRST> <TASKD_USER_LAST>/<USER_ID>
```

**IMPORTANT**: The <HOSTNAME> MUST be the same name as hostname container. Edit 
your `/etc/hosts` if necessary.

4. Execute your first sync

```
    task sync init
```

### Android Client

Make it work the Taskwarrior Android Client is easy. https://play.google.com/store/apps/details?id=kvj.taskw

Just follow the recommended settings https://bitbucket.org/kvorobyev/taskwarriorandroid/wiki/Configuration and add this configuration in `.taskrc.android` and you are done.

```
taskd.certificate=/path/to/first_last.cert.pem
taskd.key=/path/to/first_last.key.pem
taskd.ca=/path/to/ca.cert.pem
taskd.server=office.fritz.box:53589
taskd.credentials=OrgName/first_last/01234567-89abc-cdef-0123-456789abcdef
```

Source: https://blag.nullteilerfrei.de/2016/08/05/taskwarrior-on-android/
