import pyodbc

print('connect to sql server')

server = 'sql' 
database = 'master' 
username = 'sa' 
password = 'MyPass@word' 
cnxn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()

print('connected to sql server')