import numpy as np
import pandas as pd
import yfinance as yf
import datetime as datetime
import ta
import statsmodels.api as sm
from statsmodels.tsa.stattools import coint
from hurst import compute_Hc
import warnings
warnings.filterwarnings("ignore")
import requests
from tqdm import tqdm
import math


def get_earliest_available_date(symbol, interval='1d'):
    """
    Get the earliest available date for a given symbol on Binance.
    
    Parameters:
    - symbol (str): The trading pair symbol (e.g., BTCUSDT).
    - interval (str): The time interval (e.g., 1d for daily data).
    
    Returns:
    - str: The earliest available date in 'YYYY-MM-DD' format.
    """
    url = 'https://api.binance.com/api/v3/klines'
    params = {
        'symbol': symbol,
        'interval': interval,
        'limit': 1,
        'startTime': 0  # Start from the very first available timestamp
    }
    response = requests.get(url, params=params)
    data = response.json()
    if data:
        earliest_timestamp = data[0][0]
        earliest_date = datetime.datetime.utcfromtimestamp(earliest_timestamp / 1000).strftime('%Y-%m-%d')
        return earliest_date
    else:
        return None

def get_latest_available_date(symbol, interval='1d'):
    """
    Get the latest available date for a given symbol on Binance.
    
    Parameters:
    - symbol (str): The trading pair symbol (e.g., BTCUSDT).
    - interval (str): The time interval (e.g., 1d for daily data).
    
    Returns:
    - str: The latest available date in 'YYYY-MM-DD' format.
    """
    url = 'https://api.binance.com/api/v3/klines'
    params = {
        'symbol': symbol,
        'interval': interval,
        'limit': 1,
        'endTime': int(datetime.datetime.now().timestamp() * 1000)  # Up to the current timestamp
    }
    response = requests.get(url, params=params)
    data = response.json()
    if data:
        latest_timestamp = data[0][6]  # 'Close Time' is the 7th element
        latest_date = datetime.datetime.utcfromtimestamp(latest_timestamp / 1000).strftime('%Y-%m-%d')
        return latest_date
    else:
        return None


def get_earliest_and_latest_dates(symbols, interval='1d'):
    """
    Retrieve the earliest and latest available dates for each symbol.
    
    Parameters:
    - symbols (list): List of trading pairs on Binance.
    - interval (str): The time interval (e.g., 1d for daily data).
    
    Returns:
    - pd.DataFrame: DataFrame with the earliest and latest available dates for each symbol.
    """
    date_info = []
    for symbol in tqdm(symbols, desc="Fetching earliest and latest dates"):
        earliest_date = get_earliest_available_date(symbol, interval)
        latest_date = get_latest_available_date(symbol, interval)
        if earliest_date and latest_date:
            date_info.append({'Symbol': symbol, 'EarliestDate': earliest_date, 'LatestDate': latest_date})
    return pd.DataFrame(date_info)

def get_all_binance_symbols():
    """
    Retrieve all available cryptocurrency trading pairs from Binance.
    
    Returns:
    - list: A list of trading pairs on Binance.
    """
    url = 'https://api.binance.com/api/v3/exchangeInfo'
    response = requests.get(url)
    response.raise_for_status()
    data = response.json()
    return [s['symbol'] for s in data['symbols'] if s['quoteAsset'] == 'USDT']


def get_normalized_data(ticker, start, end ):
    """
    This function retrieves and processes historical stock data for a given ticker.

    Parameters:
    - ticker (str): The stock ticker symbol.
    - start (date): The start date of the historical data in the format of a datetime object.
    - end (date): The end date of the historical data in the format of a datetime object.

    Returns:
    - pandas.DataFrame: A DataFrame containing the processed historical data for the given ticker.

    The function first retrieves the historical data for the specified ticker using the yfinance library. It then filters the data to include only the 'Volume' and 'Close' columns. Next, it calculates a 200-day simple moving average (SMA) of the 'Close' prices and adds a new column to the DataFrame. The function then removes any rows with missing values. Finally, it calculates the normalized daily returns and adds a new column to the DataFrame. The function then removes any remaining rows with missing values and returns the processed DataFrame.
    """
    data = yf.Ticker(ticker)
    data = data.history(period='1d', start=start, end=end)
    data = data[['Volume','Close']]
    data.loc[:, '200SMA'] = ta.trend.sma_indicator(data['Close'], window=200)
    data.dropna(inplace=True)
    data.loc[:, 'NormalizedClose'] = data['Close']/data['200SMA']
    data.loc[:, 'dailyReturn'] = data['Close'].pct_change()
    data.loc[:, 'normalizedDailyReturn'] = data['NormalizedClose'].pct_change()
    data.dropna(inplace=True)
    return data.dropna()

def compute_half_life(series):
    """
    This function calculates the half-life of a given time series.

    Parameters:
    - series (pd.Series): A pandas Series containing the time series data.

    Returns:
    - float: The half-life of the time series.

    The function first creates a DataFrame from the input series. It then calculates the lagged values of the series. After that, it performs a linear regression analysis using the Ordinary Least Squares (OLS) method. The beta coefficient of the regression is then extracted, which represents the rate of decay of the time series. Finally, the half-life of the time series is calculated using the formula: half_life = -log(2) / log(beta).
    """
    # data = pd.DataFrame(series, columns=['NormalizedClose'])
    data = pd.DataFrame(series).rename(columns={'Close': 'NormalizedClose'}).reset_index(drop=True)

    data['lagged'] = data['NormalizedClose'].shift(1)
    data.dropna(inplace=True)

    # Add a constant to the independent variable
    lagged_Xt_with_const = sm.add_constant(data['lagged'])

    # Perform regression
    regression_results = sm.OLS(data['NormalizedClose'], lagged_Xt_with_const).fit()

    # Extract the beta coefficient
    beta = regression_results.params.iloc[1]

    # Calculate half-life
    half_life = -np.log(2) / np.log(beta)
    return half_life

def half_life_test(series1, series2):
    """
    Test the half-life of two given time series.
    
    Returns:
    - dict: Dictionary containing the half-life values and a 'Pass' or 'Fail' result.
    """
    half_life1 = compute_half_life(series1)
    half_life2 = compute_half_life(series2)
    result = {
        'HalfLife1': half_life1,
        'HalfLife2': half_life2,
        'HalfLifeResult': 'Pass' if (3 < half_life1 < 400) and (3 < half_life2 < 400) else 'Fail'
    }
    return result


def hurst_exponent_test(series1, series2):
    """
    Test the Hurst exponent of two given time series.
    
    Returns:
    - dict: Dictionary containing the Hurst exponent values, half-life results, and a final 'Pass' or 'Fail' result.
    """
    H1, c1, _ = compute_Hc(series1, kind='price', simplified=True)
    H2, c2, _ = compute_Hc(series2, kind='price', simplified=True)
    result = {
        'Hurst1': H1,
        'Hurst2': H2,
        'HurstResult': 'Pass' if H1 < 0.7 and H2 < 0.7 else 'Fail'
    }

    if result['HurstResult'] == 'Pass':
        half_life_result = half_life_test(series1, series2)
        result.update(half_life_result)
        result['OverallResult'] = 'Pass' if half_life_result['HalfLifeResult'] == 'Pass' else 'Fail'
    else:
        result['OverallResult'] = 'Fail'

    return result



def cointegration_test(series1, series2):
    """
    Test if two given time series are cointegrated.
    
    Returns:
    - dict: Dictionary containing cointegration results, Hurst exponent results, and a final 'Pass' or 'Fail' result.
    """
    score, p_value, _ = coint(series1, series2)
    result = {
        'CointegrationScore': score,
        'CointegrationPValue': p_value,
        'CointegrationResult': 'Pass' if p_value < 0.3 else 'Fail'
    }

    if result['CointegrationResult'] == 'Pass':
        hurst_result = hurst_exponent_test(series1, series2)
        result.update(hurst_result)
        result['OverallResult'] = 'Pass' if hurst_result['OverallResult'] == 'Pass' else 'Fail'
    else:
        result['OverallResult'] = 'Fail'

    return result


def get_historical_klines(symbol, interval, start_str, end_str=None):
    """
    Retrieve historical klines data for a given trading pair from Binance and ensure the data is numeric, complete, and standardized.

    Parameters:
    - symbol (str): The trading pair symbol (e.g., BTCUSDT).
    - interval (str): The time interval (e.g., '1d' for daily data).
    - start_str (int): The start time in Unix milliseconds.
    - end_str (int, optional): The end time in Unix milliseconds. Defaults to None.

    Returns:
    - pd.Series: Series containing the processed 'Close' price data.
    """
    # Define the Binance API URL
    url = 'https://api.binance.com/api/v3/klines'

    # Set the parameters for the API request
    params = {
        'symbol': symbol,
        'interval': interval,
        'startTime': start_str,
        'endTime': end_str,
        'limit': 1000  # We can fetch up to 1000 entries per call
    }

    # Make the GET request
    response = requests.get(url, params=params)

    # Raise an exception if the call was unsuccessful
    response.raise_for_status()

    # Parse the JSON response
    data = response.json()

    # Convert the data to a pandas DataFrame and set column names
    df = pd.DataFrame(data)
    df.columns = [
        'Open Time', 'Open', 'High', 'Low', 'Close', 'Volume', 'Close Time',
        'Quote Asset Volume', 'Number of Trades', 'Taker Buy Base Asset Volume',
        'Taker Buy Quote Asset Volume', 'Ignore'
    ]

    # Convert timestamps to datetime objects
    df['Open Time'] = pd.to_datetime(df['Open Time'], unit='ms')
    df['Close Time'] = pd.to_datetime(df['Close Time'], unit='ms')

    # Ensure numeric conversion for key columns
    df[['Open', 'High', 'Low', 'Close', 'Volume']] = df[['Open', 'High', 'Low', 'Close', 'Volume']].apply(pd.to_numeric, errors='coerce')

    # Fill missing data only if less than 30% is missing
    missing_percentage = df['Close'].isna().mean() * 100
    if missing_percentage < 30:
        df['Close'].fillna(method='ffill', inplace=True)
        df['Close'].fillna(method='bfill', inplace=True)

    # Add technical indicators and drop rows with missing values
    df['200SMA'] = ta.trend.sma_indicator(df['Close'], window=200)
    df.dropna(inplace=True)

    # Normalize the Close prices
    df['NormalizedClose'] = df['Close'] / df['200SMA']

    # Return the Close prices as a Series
    return df['Close'].astype(float)

def run_cointegration_tests(symbols, interval, start_str, end_str):
    """
    Run cointegration tests for all pairs of symbols and store results in a DataFrame.
    
    Returns:
    - pd.DataFrame: DataFrame containing test results for each pair.
    """
    results = []
    num_pairs = math.comb(len(symbols), 2)
    
    for i in tqdm(range(len(symbols)), desc="Testing pairs"):
        for j in range(i + 1, len(symbols)):
            symbol1 = symbols[i]
            symbol2 = symbols[j]
            try:
                series1 = get_historical_klines(symbol1, interval, start_str, end_str)
                series2 = get_historical_klines(symbol2, interval, start_str, end_str)
                if not series1.empty and not series2.empty:
                    test_result = cointegration_test(series1, series2)
                    results.append({
                        'Symbol1': symbol1,
                        'Symbol2': symbol2,
                        **test_result,
                        'Error': None  # No error
                    })
                else:
                    results.append({
                        'Symbol1': symbol1,
                        'Symbol2': symbol2,
                        'CointegrationScore': None,
                        'CointegrationPValue': None,
                        'CointegrationResult': None,
                        'Hurst1': None,
                        'Hurst2': None,
                        'HurstResult': None,
                        'HalfLife1': None,
                        'HalfLife2': None,
                        'HalfLifeResult': None,
                        'OverallResult': None,
                        'Error': 'No data available for one or both symbols'
                    })
            except Exception as e:
                results.append({
                    'Symbol1': symbol1,
                    'Symbol2': symbol2,
                    'CointegrationScore': None,
                    'CointegrationPValue': None,
                    'CointegrationResult': None,
                    'Hurst1': None,
                    'Hurst2': None,
                    'HurstResult': None,
                    'HalfLife1': None,
                    'HalfLife2': None,
                    'HalfLifeResult': None,
                    'OverallResult': None,
                    'Error': str(e)
                })
    
    print(f"Pairs Tested: {len(results)}/{num_pairs}")
    return pd.DataFrame(results)


if __name__ == "__main__":
    
    ###### (Step 1) Find Binance symbols quoted in USDT, with data between 2020-01-01 to 2024-05-03
    symbols = get_all_binance_symbols()
    interval = '1d'
    date_info_df = get_earliest_and_latest_dates(symbols, interval)
    print(date_info_df.head())
    earliest_and_latest_csv_path = 'binance_earliest_and_latest_dates.csv'
    date_info_df.to_csv(earliest_and_latest_csv_path, index=False)
    print(f"Binance earliest and latest dates saved to: {earliest_and_latest_csv_path}")
    start_date = '2020-01-01'
    end_date = '2024-05-03'
    filtered_symbols_df = date_info_df[
        (date_info_df['EarliestDate'] <= start_date) &
        (date_info_df['LatestDate'] >= end_date)
    ]
    filtered_symbols_csv_path = 'binance_filtered_symbols_2020_2024.csv'
    filtered_symbols_df.to_csv(filtered_symbols_csv_path, index=False)
    print(f"Filtered symbols saved to: {filtered_symbols_csv_path}")
    
    # Terminal Output
    #     Fetching earliest and latest dates: 100%|██████████| 500/500 [05:55<00:00,  1.41it/s]
    #     Symbol EarliestDate  LatestDate
    # 0  BTCUSDT   2017-08-17  2024-05-09
    # 1  ETHUSDT   2017-08-17  2024-05-09
    # 2  BNBUSDT   2017-11-06  2024-05-09
    # 3  BCCUSDT   2017-11-11  2018-11-20
    # 4  NEOUSDT   2017-11-20  2024-05-09
    # Binance earliest and latest dates saved to: binance_earliest_and_latest_dates.csv
    # Filtered symbols saved to: binance_filtered_symbols_2020_2024.csv
    
    ###### (Step 2) Run Cointegration Tests on each pair
    filtered_symbols_csv_path = 'binance_filtered_symbols_2020_2024.csv'
    filtered_symbols_df = pd.read_csv(filtered_symbols_csv_path)
    symbols = filtered_symbols_df['Symbol'].tolist()

    num_symbols = len(symbols)
    print(f"Number of symbols in the filtered list: {num_symbols}")
    num_pairs = math.comb(num_symbols, 2)
    print(f"Number of possible pairs: {num_pairs}")
    
    # # train test split 80-20, 3.5 years to 1 year
    # # training set 2020-01-01 to 2023-06-01
    # # testing set 2023-06-01 to 2024-05-03
    interval = "1d"
    start_str = int(datetime.datetime(2020, 1, 1).timestamp() * 1000)
    end_str = int(datetime.datetime(2023, 6, 1).timestamp() * 1000)

    # Run cointegration tests for all pairs
    results_df = run_cointegration_tests(symbols, interval, start_str, end_str)
    results_csv_path = 'cointegration_results.csv'
    results_df.to_csv(results_csv_path, index=False)
    print(f"Cointegration results saved to: {results_csv_path}")
    
    # Terminal Output
    # Number of symbols in the filtered list: 69
    # Number of possible pairs: 2346
    # Testing pairs: 100%|██████████| 69/69 [36:49<00:00, 32.02s/it] 
    # Pairs Tested: 2346/2346
    # Cointegration results saved to: cointegration_results.csv

    # cointegration_results.csv 
    # Symbol1	Symbol2	CointegrationScore	CointegrationPValue	CointegrationResult	OverallResult	Error	Hurst1	Hurst2	HurstResult	HalfLife1	HalfLife2	HalfLifeResult
    # ZECUSDT	XTZUSDT	-3.024366181	0.104526659	Pass	Pass		0.668873904	0.690041193	Pass	40.91657079	45.72652463	Pass
    # ZECUSDT	KAVAUSDT	-2.949486113	0.122706202	Pass	Pass		0.668873904	0.672012069	Pass	40.91657079	47.70218779	Pass
    # XTZUSDT	KAVAUSDT	-3.48187389	0.034036413	Pass	Pass		0.690041193	0.672012069	Pass	45.72652463	47.70218779	Pass


 