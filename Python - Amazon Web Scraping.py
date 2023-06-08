#!/usr/bin/env python
# coding: utf-8

def main():
    
    import time             #Schedule job

    SECONDS_IN_DAY = 86400  #60sec * 60min * 24hr
    
    url = r'https://www.amazon.com/funny-analyst-definition-scientist-t-shirt/dp/B07NLP2PKY/ref=sr_1_1?crid=2PUV6JKRK66RW&keywords=data+analyst+tshirt&qid=1686240772&sprefix=data+analyst+tshirt%2Caps%2C101&sr=8-1'                                                                                                               #Grabbed a random data analyst shirt from Amazon
    
    #Probably don't want to hard-code my credentials, so ask for them
    my_email = input('Enter your email address: ')
    my_password = input('Enter your email password: ')
    
    #Check the shirt price once a day, send an email if the price drops
    while(True):
        shirt_price = check_shirt_price(url)
        if float(shirt_price) < 25:
            send_mail(my_email, my_password, url)
        time.sleep(SECONDS_IN_DAY)

def check_shirt_price(url):
    
    import requests                #Send HTTP requests
    from bs4 import BeautifulSoup  #HTML parsing
    import datetime                #Timestamps
    import os                      #File management
    import csv                     #Ouput data to a CSV file
    
    #Connect to an Amazon item page
    my_headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36", "Accept-Encoding":"gzip, deflate", "Accept":"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "DNT":"1","Connection":"close", "Upgrade-Insecure-Requests":"1"}  #Obtained from http://httpbin.org/get
    page = requests.get(url, headers = my_headers)

    soup1 = BeautifulSoup(page.content, 'html.parser')
    soup2 = BeautifulSoup(soup1.prettify(), 'html.parser')

    #Pull the item data we want
    today = datetime.date.today()
    title = soup2.find(id = 'productTitle').get_text()
    price = soup2.find('span', class_="a-offscreen").get_text()
    rating = soup2.find('span', class_="a-size-base").get_text()
    ratings_count = soup2.find(id = 'acrCustomerReviewText').get_text().replace(' ratings', '')

    #Cleanup the data, notice these are all strings
    title = title.strip()
    price = price.strip()[1:]
    rating = rating.strip()
    ratings_count = ratings_count.strip()

    #Write the data to CSV
    file_path = r'C:\Users\bstou\Desktop\Data Analyst\Python\18 Amazon Web Scraping Project\AmazonShirtDataset.csv'
    csv_header = ['Date', 'Title', 'Price', 'Rating', 'Ratings Count']
    data = [today, title, price, rating, ratings_count]

    write_header = True
    if os.path.exists(file_path):
        write_header = False

    with open(file_path, 'a+', newline = '', encoding = 'UTF8') as myFile:
        writer = csv.writer(myFile)
        if write_header:
            writer.writerow(csv_header)
        writer.writerow(data)
        
    return price

def send_mail(email, password, url):
    
    import smtplib                 #Send emails
    
    server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
    server.ehlo()
    server.login(email, password)
    
    subject = "The Shirt you want is below $25! Now is your chance to buy!"
    body = "This is the moment we have been waiting for. Now is your chance to pick up the shirt of your dreams. Don't mess it up! \n\nLink here: " + url
   
    msg = f"Subject: {subject}\n\n{body}"
    
    server.sendmail(email, email, msg)
    

