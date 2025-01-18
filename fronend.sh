#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){

    if [ $USERID -ne 0 ]
    then
       echo "ERROR: you must have sudo access"
       exit1 ## other then the root 
    fi
       
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install nginx -y 
VALIDATE $? " Installing nginx server"

systemctl enable nginx
VALIDATE $? " Enabling nginx service"

systemctl start nginx
VALIDATE $? " Starting nginx service"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "cleaning up default html code"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip
VALIDATE $? "downloading frontend files"

cd /usr/share/nginx/html
VALIDATE $? "moving to html code to dir"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/
VALIDATE $? "coping expense html conf file"

systemctl restart nginx
VALIDATE $? " Restarting nginx service"
