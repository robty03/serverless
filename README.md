# Serverless TODO Application

This project implements a serverless architecture on AWS.

Architecture:

1. EventBridge (scheduled every 5 minutes)
2. Lambda (todo-submit)
3. DynamoDB
4. SQS queue
5. Lambda (todo-processor)
6. DynamoDB update  

The first Lambda creates a TODO item in DynamoDB and sends a message to SQS.
The second Lambda processes the message and updates the status of the item.
