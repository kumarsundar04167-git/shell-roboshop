#!/bin/bash
userid=$(id -u)
LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.devopsonline.online

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
        echo -e " $TIMESTAMP $R [ERROR] $N given $1 is ..... $R failed $N"   | tee -a $LOGS_FILE
        exit 1
    else
        echo -e " $TIMESTAMP $Y [INFO] $N given $1 is ..... $G success $N"   | tee -a $LOGS_FILE
    fi
}

dnf install maven -y  &>>  $LOGS_FILE
validate "installing maven" $?

rm -rf /app
validate "removing app directory" $?

rm -rf /tmp/shipping.zip
validate "removing zip file" $?

mkdir -p /app
validate "creating app directory" $?

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
cd /app 
unzip /tmp/shipping.zip  &>>  $LOGS_FILE
validate "download and extracting code" $?

cd /app 
mvn clean package 
mv target/shipping-1.0.jar shipping.jar &>>  $LOGS_FILE
validate "installing dependencies" $?

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service  &>>  $LOGS_FILE
validate "copying service file" $?


dnf install mysql -y   &>>  $LOGS_FILE
validate "installing mysql" $?

mysql -h $MYSQL_HOST -u root -pRoboShop@1 -e "use cities"
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
    validate "loading master data " $?
else
    echo -e " $TIMESTAMP $Y [INFO] $N data already loaded ...... $Y skipping $N "
fi

systemctl daemon-reload
systemctl enable shipping
systemctl start shipping   &>>  $LOGS_FILE
validate "enable and restarted shipping" $?
