output "queue_url" {
  value = aws_sqs_queue.todo_queue.id
}

output "table_name" {
  value = aws_dynamodb_table.todo_table.name
}