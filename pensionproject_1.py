import pandas as pd
from sodapy import Socrata
from sqlalchemy import create_engine


client = Socrata("data.cityofnewyork.us", app_token = "...", timeout = 60) ##Enter your own app_token here



limit = 1000
offset = 0
all_results = []
while True:
    results = client.get("p3e6-t4zv", limit = limit, offset = offset) ##first argument is the nycers pension dataset.
    if not results:
        print("No more records. Ending pagination")
        break
    all_results.extend(results)
    offset += limit
    print(f"Retrieved {len(all_results)} rows so far...")

if all_results:
    df = pd.DataFrame.from_records(all_results)
    print(f"Final dataset shape: {df.shape}")
    server = "localhost"
    database = "nycers_data_project"
    driver = 'ODBC Driver 17 for SQL Server'
    connection_string = f"mssql+pyodbc://@{server}/{database}?driver={driver}&trusted_connection=yes"
    engine = create_engine(connection_string)
    df.to_sql('nycers_holdings', con=engine, if_exists='replace', index=False)
    print("Data uploaded to SQL server")
else:
    print("No data uploaded.")

pd.set_option("display.max_columns", None)
print(df.shape)

cols_to_convert_to_numeric = ["original_face", "shares_par_value", "base_market_value", "base_total_cost", "base_unrealized_gain_loss", "base_accrued_interest", "local_market_value"
                              ,"local_total_cost_amount", "local_unrealized_gain_loss", "local_accrued_interest"]
for col in cols_to_convert_to_numeric:
    df[col] = pd.to_numeric(df[col])

cols_to_convert_to_date = ["maturity_date","period_end_date", "data_as_of"]
for col in cols_to_convert_to_date:
    df[col] = pd.to_datetime(df[col])