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

dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Mysql server "

systemctl enable mysqld &>>$LOG_FILE_NAME
VALIDATE $? "enabling mysqld"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $?  "My sql servcie started"

mysql_secure_installation --set-root-pass ExpenseApp@1
VALIDATE $?   "setting of Root password for mysql"

if [ $? -ne 0 ]
then
  echo "MYSQL Root password is not setup"
  VALIDATE $?  "Setting up root password"

else
  echo "MYSQL Root password already setup.... $Y Skipping $N"
  
fi