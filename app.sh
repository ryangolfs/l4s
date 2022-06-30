#!/bin/bash

git clone https://github.com/christophetd/log4shell-vulnerable-app.git
git clone https://github.com/ryangolfs/jndi.git
mv -f /tmp/Dockerfile /root/log4shell-vulnerable-app
docker build -t app /root/log4shell-vulnerable-app
unzip /root/jndi/JNDIExploit.v1.2.zip -d /root/jndi
docker run --name vulnerable-app -p 8080:8080 app &
java -jar /root/jndi/JNDIExploit-1.2-SNAPSHOT.jar -i $(curl -s ifconfig.co) -p 8888 &
