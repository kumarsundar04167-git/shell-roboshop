#!/bin/bash
userid=$(id -u)
LOGS_DIR="var/log/roboshop"
sudo mkdir -p $LOGS_DIR
sudo chown -R ec2-user:ec2-user $LOGS_DIR
sudo chmod -R 755 $LOGS_DIR
LOGS_FILE="$LOGS_DIR/$0.log"
SCRIPT_DIR=$pwd

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
        echo -e " $TIMESTAMP $Y [INFO] $N given $1 is ..... $G success $N"   | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y
dnf module enable nodejs:20 -y  &>>  $LOGS_FILE
validate "enabled nodejs:20" $?

dnf install nodejs -y
validate "installing nodejs" $?

rm -rf /app
validate "removing app directory" $?

rm -rf /tmp/cart.zip
validate "removing zip file" $?

mkdir -p /app
validate "creating app directory" $?

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
cd /app 
unzip /tmp/cart.zip   &>>  $LOGS_FILE
validate "download and extracting code" $?

cd /app 
npm install   &>>  $LOGS_FILE
validate "installing dependencies" $?

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service  &>>  $LOGS_FILE
validate "copying service file" $?

systemctl daemon-reload
systemctl enable cart
systemctl start cart   &>>  $LOGS_FILE
validate "enable and restarted cart" $?

