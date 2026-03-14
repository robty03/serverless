import boto3
import json

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("todo-table")

def lambda_handler(event, context):

    for record in event["Records"]:

        body = json.loads(record["body"])
        todo_id = body["todo_id"]

        table.update_item(
            Key={"todo_id": todo_id},
            UpdateExpression="SET #s = :s",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":s": "processed"}
        )

    return "done"