#!/bin/bash
userid=$(id -u)
LOGS_DIR=var/log/roboshop
sudo mkdir -p $LOGS_DIR
sudo chown -R ec2-user:ec2-user $LOGS_DIR
sudo chmod -R 755 $LOGS_DIR
LOGS_FILE=$LOGS_DIR/$0.log
SCRIPT_DIR=$pwd

TIMESTAMP=$(date "+%H:%M:%S")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $userid -ne 0 ]; then
     echo -e " $TIMESTAMP $R [ERROR] $N $Y please run this as root user $N"
     exit 1
fi

validate(){
    if [ $2 -ne 0 ]; then
        echo -e " $TIMESTAMP $R [ERROR] $N given $1 is ..... $R failed $N"
        exit 1
    else
        echo -e " $TIMESTAMP $Y [INFO] $N given $1 is ..... $G success $N"
    fi
}

dnf module disable nodejs -y
dnf module enable nodejs:20 -y
validate "disabled and enable nodejs:20" $?

dnf install nodejs -y
validate "installing nodejs" $?

id roboshop
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate "adding system user" $?
else
   echo -e " $TIMESTAMP $Y [INFO] $N already roboshop system user exists ..... $Y skipping $N "
fi

rm -rf /app
validate "removing app directory" $?

rm -rf /tmp/catalogue.zip
validate "removing zip file" $?

mkdir -p /app
validate "creating app directory" $?

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd /app 
unzip /tmp/catalogue.zip
validate "download and extracting code" $?

cd /app 
npm install 
validate "installing dependencies" $?

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
validate "copying service file" $?

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
validate "copying mongo.repo" $?

dnf install mongodb-mongosh -y
validate "installing mongodb client" $?

INDEX=$(mongosh --host mongodb.devopsonline.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -lt 0 ]; then
    mongosh --host mongodb.devopsonline.online </app/db/master-data.js
    validate "products loaded" $?
else
    echo -e " $TIMESTAMP already products loaded ..... $Y skipping $N "
fi

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue
validate "enabled and restarted catalogue" $?