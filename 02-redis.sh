#!/bin/bash
userid=$(id -u)
LOGS_DIR=/var/log/roboshop
sudo mkdir -p $LOGS_DIR
sudo chown -R ec2-user:ec2-user $LOGS_DIR
sudo chmod -R 755 $LOGS_DIR
LOGS_FILE=$LOGS_DIR/$0.log

TIMESTAMP=$(date "+%Y-%M-%D %H:%M:%S")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $userid -ne 0 ]; then
    echo -e " $TIMESTAMP $Y [ERROR] $N please run this as a root user $N" | tee -a $LOGS_FILE
    exit 1
fi

validate(){
    if [ $2 -ne 0 ]; then
        echo -e " $TIMESTAMP $R [ERROR] $N $2 is ..... $R failed $N " | tee -a $LOGS_FILE
        exit 1
    else
        echo -e " $TIMESTAMP $Y [info] $N $2 is .....$G success $N " | tee -a $LOGS_FILE
    fi
}    

dnf module disable redis -y  &>> $LOGS_FILE
dnf module enable redis:7 -y &>> $LOGS_FILE
validate "enabling redis:7" $?

dnf install redis -y  &>> $LOGS_FILE
validate "installing redis" $?

sed -i -e 's/127.0.0.1/0.0.0.0/g'  -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf  &>> $LOGS_FILE
validate "allowing remote connections and protected mode change" $?

systemctl enable redis  &>> $LOGS_FILE
validate "enabling redis" $?

systemctl start redis  &>> $LOGS_FILE
validate "starting redis" $?