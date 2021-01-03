# jigowatt

A 100% community Open Source client for InfluxDB 2.0. 

Currently, Jigowatt's features focus on viewing an account, including writing queries and viewing dashboards.

Jigowatt is powered by the Open Source toolkit [Flux Mobile](https://gitlab.com/rickspencer3/flux-mobile).

## Getting Started
### Add an Account
Start by clicking the "Account" button in the top left. 

This will bring you to your account list, which is empty. Click the "+" at the bottom to add your first account. Fill it in as below:

| Field | Notes |
|---|---|
| active? | If this is the first account you added, set it to active here. Otherwise, leave it off. |
| Org Id | This is the random alpha numeric string of your org, not the name of your org in InfluxDB. |
| URL | The URL where your account can be reached, including the trailed "/." For example: "https://us-west-2-1.aws.cloud2.influxdata.com/". This should work fine pointed to your own running Open Source instance of InfluxDB 2.0 as well. |
| Token | This is an all access Token for your account so you can see all dashboards, and query all buckets. |

#### Finding your Org Id
Log into InfluxDB in your browser, and in the upper left, you can access user info. Your Org Id is there ready to be copied.



### Viewing Dashboards

### Writing a Query


