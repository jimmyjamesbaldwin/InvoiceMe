import os
import json
import boto3
from botocore.vendored import requests
from botocore.client import Config
from datetime import datetime, date

# aws sdk
s3_client             = boto3.client('s3')
dynamodb_client       = boto3.client('dynamodb')
secretsmanager_client = boto3.client('secretsmanager')

# vars
today                 = str(date.today())
output_dir            = '/tmp/'
output_file           = today + '.pdf'

# secrets
secrets = json.loads(secretsmanager_client.get_secret_value(SecretId='InvoiceMe')['SecretString'])

def lambda_handler(event, context):
	try:
		generate_invoice(output_dir, output_file)
		slack_notification(upload_to_s3(s3_client, output_dir, output_file))
		increment_invoice_number()
	except Exception as e:
		return {'statusCode': 500, 'errorMsg': str(e)}
	return {'statusCode': 200}


def get_timesheet_data():
	'''Pulls timesheet data from Harvest'''
	headers = {
		'Authorization': secrets['harvest_auth'],
		'Harvest-Account-ID': os.environ['harvest_id']
	}
	return requests.get(os.environ['harvest_url'], headers=headers)


def parse_timesheet_data(day_rate):
	'''Parses timesheet data, calculates days to bill for'''
	invoice_lines = []
	full_days = 0
	half_days = 0

	for i in get_timesheet_data().json()['time_entries']:
		spent_date = (date(*map(int, i['spent_date'].split('-'))))

		if (spent_date >= datetime.today().replace(day=1).date()):
			if (i['hours'] == 8.0):
				full_days = full_days + 1
			elif (i['hours'] == 4.0):
				half_days = half_days + 1
			else:
				print('Got a time entry with a ' + i['hours'] + '...') # wth
	if (full_days != 0): 
		invoice_lines.append({"name": "IT Consulting Services", "quantity": full_days, "unit_cost": day_rate})
	if (half_days != 0): 
		invoice_lines.append({"name": "IT Consulting Services (half day)", "quantity": half_days, "unit_cost": day_rate/2})
	return invoice_lines


def generate_invoice_payload():
	'''Builds the invoice object'''
	invoice = load_config()
	invoice['number'] = get_invoice_number()
	invoice['items'] = parse_timesheet_data(invoice['day_rate']) 
	return invoice


def generate_invoice(output_dir, output_file):
	'''POSTs the invoice payload to invoiced'''
	response = requests.post(
		os.environ['invoice_generator_url'], 
		json=generate_invoice_payload())
	with open(output_dir + output_file, 'wb') as f:
		f.write(response.content)


def upload_to_s3(s3_client, output_dir, output_file):
	'''Upload the pdf to s3 and create a presigned url for downloads'''
	s3_resource = boto3.resource('s3')
	s3_resource.Bucket(os.environ['s3_bucket']).upload_file(output_dir + output_file, output_file)

	return s3_client.generate_presigned_url(
		ClientMethod='get_object',
		Params={'Bucket': os.environ['s3_bucket'], 'Key': str(today + '.pdf')},
		ExpiresIn=604800 # 1 week
	)


def slack_notification(invoice_url):
	'''Sends a slack message with our presigned url'''
	slack_data = {'text': os.environ['slack_message'] + invoice_url}
	response = requests.post(
	    secrets['slack_webhook'], 
	    data=json.dumps(slack_data),
	    headers={'Content-Type': 'application/json'}
	)


def load_config():
	'''Loads static invoice content from a json file'''
	with open('config.json', 'r') as configfile:
		return json.load(configfile)


def get_invoice_number():
	'''Queries dynamodb to get the number for this invoice'''
	db_record = dynamodb_client.get_item(TableName='InvoiceMe', Key = {"Id":{"N":'1'}})
	return db_record['Item']['InvoiceNumber']['N']


def increment_invoice_number():
	'''Increments dynamodb with the next invoice number'''
	dynamodb_client.update_item(
		TableName='InvoiceMe',
		Key = {"Id":{"N":'1'}},
		UpdateExpression="set InvoiceNumber = :n",
		ExpressionAttributeValues={
			':n': {'N': str(int(get_invoice_number()) + 1)}
		},
		ReturnValues="UPDATED_NEW"
	)
