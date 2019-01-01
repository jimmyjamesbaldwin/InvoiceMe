# db table structure
resource "aws_dynamodb_table" "table" {
  name           = "${var.app_name}"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "N"
  }
}

# seed database
resource "aws_dynamodb_table_item" "seed_data" {
  table_name = "${aws_dynamodb_table.table.name}"
  hash_key   = "${aws_dynamodb_table.table.hash_key}"

  item = <<ITEM
{
  "Id": {"N": "1"},
  "InvoiceNumber": {"N": "1"}
}
ITEM
}