import boto3
import json
import uuid

dynamodb = boto3.resource("dynamodb")
sqs = boto3.client("sqs")

table = dynamodb.Table("todo-table")

QUEUE_URL = "https://sqs.eu-north-1.amazonaws.com/022038145754/todo-queue"

def lambda_handler(event, context):

    todo_id = str(uuid.uuid4())

    table.put_item(
        Item={
            "todo_id": todo_id,
            "title": "Example task",
            "status": "pending"
        }
    )

    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps({"todo_id": todo_id})
    )

    return {
        "statusCode": 200,
        "body": "Todo created"
    }