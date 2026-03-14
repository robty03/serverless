# Serverless TODO Application

This project implements a serverless architecture on AWS.

Architecture:

EventBridge (scheduled every 5 minutes)
Lambda (todo-submit)     ↓
DynamoDB
SQS queue
Lambda (todo-processor)
DynamoDB update  

The first Lambda creates a TODO item in DynamoDB and sends a message to SQS.
The second Lambda processes the message and updates the status of the item.
