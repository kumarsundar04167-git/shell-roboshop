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
     echo -e " $TIMESTAMP $R [ERROR] $N $Y please run this as root user $N" | tee -a $LOGS_FILE  
     exit 1
fi

validate(){
    if [ $2 -ne 0 ]; then
        echo -e " $TIMESTAMP $R [ERROR] $N given $1 is ..... $R failed $N"   | tee -a $LOGS_FILE
        exit 1
    else
        echo -e " $TIMESTAMP $Y [INFO] $N given $1 is ..... $G success $N"   | tee -a $LOGS_FILE
    fi
}

dnf module disable nginx -y
dnf module enable nginx:1.24 -y
dnf install nginx -y &>> $LOGS_FILE
validate "installing nginx" $?

systemctl enable nginx 
systemctl start nginx  &>> $LOGS_FILE
validate "starting nginx" $?

rm -rf /usr/share/nginx/html/* 
validate "removing default content" $?

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip  &>>  $LOGS_FILE
validate "downloading and unzipping the code" $?

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>> $LOGS_FILE
VALIDATE $? "Copied roboshop nginx conf"

systemctl restart nginx
systemctl enable nginx &>> $LOGS_FILE
VALIDATE $? "Enabled and restarted nginx"
