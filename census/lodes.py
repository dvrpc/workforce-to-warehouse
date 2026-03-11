import os
import pandas as pd
import requests
import zipfile
import io
import psycopg2


def load_lodes_data(db_uri):
    """
    Get LODES data for NJ and PA WAC Workplace Area Statistics, can adjust year in url variable
    """
    conn = psycopg2.connect(db_uri)

    lodes_states = ['nj', 'pa']
    combined_df = pd.DataFrame()

    for state in lodes_states:
        url = f"https://lehd.ces.census.gov/data/lodes/LODES8/{state}/wac/{state}_wac_S000_JT00_2021.csv.gz"
        response = requests.get(url)
        zipped_file = io.BytesIO(response.content)
        state_df = pd.read_csv(zipped_file, compression='gzip')

        combined_df = pd.concat([combined_df, state_df], ignore_index=True)

    combined_df.columns = map(str.lower, combined_df.columns)

    buffer = io.StringIO()
    combined_df.to_csv(buffer, index=False, header=False, sep='\t')
    buffer.seek(0)
    
    cur = conn.cursor()
    cur.execute(f"DROP TABLE IF EXISTS lodes_data")
    
    columns = ", ".join([f"{col} text" for col in combined_df.columns])
    cur.execute(f"CREATE TABLE lodes_data ({columns})")
    
    cur.copy_from(buffer, f'lodes_data', sep='\t')
    conn.commit()
    conn.close()