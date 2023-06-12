#!/usr/bin/env python
# coding: utf-8

# # 20 Project - Automate Pulling Cryptocurrency Price Data Via API

# In[61]:


def main():
    
    import pandas as pd
    import os
    import time
    
    SECONDS_PER_RUN = 300  #Run every 5 min
    NUMBER_OF_RUNS = 288   #Run for one day, 12 runs per hour
    
    file_path = r'C:\Users\bstou\Desktop\Data Analyst\Projects\Python\Cryptocurrency Web API\CryptoAPIDataset.csv'
    df1 = pd.DataFrame()
    
    for run in range(NUMBER_OF_RUNS):
        
        #Create a data frame for the cryptocurrency data
        crypto_data = get_crypto_listings(15)
        df2 = pd.json_normalize(crypto_data['data'])
        df2['utc_timestamp'] = pd.to_datetime('now', utc = True)
        df1 = pd.concat([df1, df2])
        
        print('CoinMarketCap API Called: ' + str(run + 1))
        
        #Write the data to CSV            
        write_header = True
        if os.path.exists(file_path):
            write_header = False

        with open(file_path, 'a+', newline = '', encoding = 'UTF8') as myFile:
            if write_header:
                df2.to_csv(myFile, header = 'column_names')
            else:
                df2.to_csv(myFile, mode = 'a', header = False)
            
        #Are we done?
        if run >= (NUMBER_OF_RUNS - 1):
            break
        time.sleep(SECONDS_PER_RUN)
        
    return df1

def get_crypto_listings(listing_limit):

    from requests import Request, Session
    from requests.exceptions import ConnectionError, Timeout, TooManyRedirects
    import json

    API_KEY = '57b66e6b-fabe-496e-8a6e-bdcb95f70858'
    
    url = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest'
    parameters = {
      'start':'1',
      'limit':listing_limit,
      'convert':'USD'
    }
    headers = {
      'Accepts': 'application/json',
      'X-CMC_PRO_API_KEY': API_KEY
    }

    session = Session()
    session.headers.update(headers)

    try:
        response = session.get(url, params=parameters)
        data = json.loads(response.text)
    except (ConnectionError, Timeout, TooManyRedirects) as e:
        data = e
    
    return data


# In[62]:


df1 = main()


# In[63]:


import seaborn as sns


# In[58]:


#How have cryptocurrency values changed over time?
df3 = df1.groupby('name', sort = False)[[
    'quote.USD.percent_change_1h',
    'quote.USD.percent_change_24h',
    'quote.USD.percent_change_7d',
    'quote.USD.percent_change_30d',
    'quote.USD.percent_change_60d',
    'quote.USD.percent_change_90d']].mean()
df3 = df3.stack()                    #Stack each cryptocurrency by time period
df3 = df3.to_frame(name = 'values')  #Convert the stack back to a dataframe
df3 = df3.reset_index()
df3 = df3.rename(columns = {'level_1': 'percent_change'})
df3['percent_change'] = df3['percent_change'].replace(['quote.USD.percent_change_1h', ], ['1h'])
df3['percent_change'] = df3['percent_change'].replace(['quote.USD.percent_change_24h', ], ['24h'])
df3['percent_change'] = df3['percent_change'].replace(['quote.USD.percent_change_7d', ], ['7d'])
df3['percent_change'] = df3['percent_change'].replace(['quote.USD.percent_change_30d', ], ['30d'])
df3['percent_change'] = df3['percent_change'].replace(['quote.USD.percent_change_60d', ], ['60d'])
df3['percent_change'] = df3['percent_change'].replace(['quote.USD.percent_change_90d', ], ['90d'])
sns.catplot(x = str('percent_change'), y = 'values', hue = 'name', data = df3, kind = 'point')


# In[64]:


#How is Bitcoin trending?
df4 = df1[['name', 'quote.USD.price', 'utc_timestamp']]
df4 = df4.query("name == 'Bitcoin'")
df4_index = pd.Index(range(len(df4)))
df4.set_index(df4_index, inplace = True)
df4['utc_timestamp'] = df4['utc_timestamp'].dt.strftime('%m/%d/%Y, %H:%M')
sns.set_theme(style = 'darkgrid')
sns.lineplot(x = 'utc_timestamp', y = 'quote.USD.price', data = df4)

