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

    if [ $USERID -ne -0 ]
    then
       echo "ERROR: you must have sudo access"
       exit1 ## other then the root 
    fi
       
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling existing node js"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Node js"

id -u expense &>>$LOG_FILE_NAME
  if [$? -ne 0]
  then
     useradd expense &>>$LOG_FILE_NAME
      VALIDATE $? "adding expense user"
  else
  echo -e "expense user already exist....$Y SKIPPING $N"
  fi

mkdir -p /app
  if [$? -ne 0]
  then
     mkdir /app
     VALIDATE $? "Creating app dir"
  else
    echo "app directory already created.....$Y SKIPPING $N"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "downloading backend"

cd /app
VALIDATE $? "switching to app dir"

unzip /tmp/backend.zip  &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping backend"

cd /app
VALIDATE $? "switching to app dir"

npm install  &>>$LOG_FILE_NAME
VALIDATE $? "Installing npm"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/
VALIDATE $? "coping backend service config file"

systemctl daemon-reload  &>>$LOG_FILE_NAME
VALIDATE $? "Reloading daemon " 

systemctl start backend  
VALIDATE $? "Starting backend service" 

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "enabling backend service" 

## Prepare Mysql schema

dnf install mysql -y  &>>$LOG_FILE_NAME
VALIDATE $? "installing MySQL client"

mysql -h mysql.ganeshdevops.online -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "setting transaction schema and tables"

systemctl daemon-reload  &>>$LOG_FILE_NAME
VALIDATE $? "Reloading daemon " 

systemctl restart backend  &>>$LOG_FILE_NAME
VALIDATE $? "Restarting backend service"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "enabling backend service" 
