#!/bin/bash
userid=$(id -u)
LOGS_DIR=var/log/roboshop
sudo mkdir -p $LOGS_DIR
sudo chown -R ec2-user:ec2-user $LOGS_DIR
sudo chmod -R 755 $LOGS_DIR
LOGS_FILE=$LOGS_DIR/$0.log

TIMESTAMP=$(date "=%H:%M:%S")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $userid -ne 0 ]; then
     echo " $TIMESTAMP $R [ERROR] $N $Y please run this as root user $N"
     exit 1
fi

validate(){
    if [ $2 -ne 0 ]; then
        echo " $TIMESTAMP $R [ERROR] $N given $1 is ..... $R failed $N"
        exit 1
    else
        echo " $TIMESTAMP $Y [INFO] $N given $1 is ..... $G success $N"
    fi
}

dnf list installed mysql-sever -y
if [ $? -ne 0 ]; then
    echo " $TIMESTAMP $Y installig mysql-server $N "
    dnf install mysql-server -y
    validete "installing mysql-sever" $?
else
    echo "mysql-server already installed ....."
fi

systemctl enable mysqld
systemctl start mysqld  
validate "enabling and starting of mysqld" $?

mysql_secure_installation --set-root-pass RoboShop@1
validate "setting root password for mysql" $?
