import boto3
import os

# import requests
sns = boto3.client("sns")
topicArn = os.getenv("TOPIC_ARN")

def lambda_handler(event, context):

    sns.publish(
        TopicArn=topicArn,
        Subject="Logged in notification: {}".format(event["userName"]),
        Message="Logged in {} in {}".format(event["userName"], event["timestamp"])
    )

    return {
        "statusCode": 200,
        "body": {"Status": "Success"},
    }
