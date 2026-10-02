#!/bin/bash
userid=$(id -u)
LOGS_DIR="/var/log/roboshop"
sudo mkdir -p "$LOGS_DIR"
sudo chown -R ec2-user:ec2-user "$LOGS_DIR"
sudo chmod -R 755 "$LOGS_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGS_FILE="$LOGS_DIR/$(basename "$0").log"

TIMESTAMP=$(date "+%H:%M:%S")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $userid -ne 0 ]; then
     echo -e " $TIMESTAMP $R [ERROR] $N $Y please run this as root user $N"  | tee -a $LOGS_FILE
     exit 1
fi

validate(){
    if [ $2 -ne 0 ]; then
        echo -e " $TIMESTAMP $R [ERROR] $N given $1 is ..... $R failed $N"  | tee -a $LOGS_FILE
        exit 1
    else
        echo -e " $TIMESTAMP $Y [INFO] $N given $1 is ..... $G success $N"  | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y
dnf module enable nodejs:20 -y  &>>  $LOGS_FILE
validate "enabled nodejs:20" $?

dnf install nodejs -y   &>>  $LOGS_FILE
validate "installing nodejs" $?

rm -rf /app
validate "removing app directory" $?

rm -rf /tmp/user.zip
validate "removing zip file" $?

mkdir -p /app
validate "creating app directory" $?

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
cd /app 
unzip /tmp/user.zip   &>>  $LOGS_FILE
validate "download and extracting code" $?

cd /app 
npm install   &>>  $LOGS_FILE
validate "installing dependencies" $?

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>  $LOGS_FILE

systemctl daemon-reload
systemctl enable user 
systemctl start user   &>>  $LOGS_FILE
validate "enable and restarted user" $?