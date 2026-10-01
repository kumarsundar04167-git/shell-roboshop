#!/bin/bash
userid=$(id -u)
LOGS_DIR=/var/log/roboshop
sudo mkdir -p $LOGS_DIR
sudo chown -R ec2-user:ec2-user $LOGS_DIR
sudo chmod -R 755 $LOGS_DIR
LOGS_FILE=$LOGS_DIR/$0.log

TIMESTAMP=$(date +%Y-%M-%D %H_%M_%S)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $userid -ne 0 ]; then
    echo -e " $TIMESTAMP $Y [ERROR] $N please run this as a root user $N" | tee -a $LOGS_FILE
    exit 1

validate(){
    if [ $2 -ne 0 ]; then
        echo -e " $TIMESTAMP $R [ERROR] $N $2 is ..... $R failed $N " | tee -a $LOGS_FILE
        exit 1
    else
        echo -e " $TIMESTAMP $Y [info] $N $2 is .....$G success $N " | tee -a $LOGS_FILE
    fi
}    

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate "copying mongo.repo file" $?

dnf install mongodb-org -y  &>> $LOGS_FILE
validate "installing mongodb" $?

systemctl enable mongod 
validate "enabling mongod" $?

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate "allowing remote connections" $?

systemctl restart mongod
validate "restarting mongod" $?

