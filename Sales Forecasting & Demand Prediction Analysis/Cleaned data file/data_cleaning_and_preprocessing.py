import os
import pandas as pd
import numpy as np

def run_preprocessing():
    print("=== Starting Data Preprocessing & Cleaning ===")
    
    # Define file paths
    raw_input_path = os.path.join("archive", "sample_-_superstore.csv")
    raw_output_path = "raw_sales_data.csv"
    clean_csv_path = "cleaned_sales_data.csv"
    clean_excel_path = "cleaned_sales_data.xlsx"

    # 1. Load raw dataset
    df_raw = pd.read_csv(raw_input_path, encoding='latin1')
    print(f"Loaded raw dataset shape: {df_raw.shape}")
    
    # Save a clean copy of raw data as raw_sales_data.csv
    df_raw.to_csv(raw_output_path, index=False)
    print(f"Saved raw dataset copy to: {raw_output_path}")

    # 2. Data Cleaning & Standardisation
    df = df_raw.copy()
    
    # Strip whitespace from column names
    df.columns = [col.strip() for col in df.columns]
    
    # Handle missing values
    # Postal Code: fill missing with 0 and convert to string formatted 5-digit zip
    if 'Postal Code' in df.columns:
        df['Postal Code'] = df['Postal Code'].fillna('Unknown').astype(str)
    
    # Date formatting
    df['Order Date'] = pd.to_datetime(df['Order Date'], format='%m/%d/%Y', errors='coerce')
    df['Ship Date'] = pd.to_datetime(df['Ship Date'], format='%m/%d/%Y', errors='coerce')
    
    # Drop any row missing critical fields like Order Date or Sales
    df = df.dropna(subset=['Order Date', 'Sales', 'Quantity'])
    
    # Sort chronologically
    df = df.sort_values(by='Order Date').reset_index(drop=True)

    # 3. Feature Engineering - Date & Time Dimensions
    df['Year'] = df['Order Date'].dt.year
    df['Month'] = df['Order Date'].dt.month
    df['Month_Name'] = df['Order Date'].dt.strftime('%b')
    df['Year_Month'] = df['Order Date'].dt.strftime('%Y-%m')
    df['Quarter'] = 'Q' + df['Order Date'].dt.quarter.astype(str)
    df['Day'] = df['Order Date'].dt.day
    df['Day_Of_Week'] = df['Order Date'].dt.day_name()
    df['Is_Weekend'] = df['Order Date'].dt.dayofweek.isin([5, 6]).astype(int)
    df['Week_Of_Year'] = df['Order Date'].dt.isocalendar().week

    # Season mapping
    def get_season(month):
        if month in [12, 1, 2]:
            return 'Winter'
        elif month in [3, 4, 5]:
            return 'Spring'
        elif month in [6, 7, 8]:
            return 'Summer'
        else:
            return 'Fall'
            
    df['Season'] = df['Month'].apply(get_season)

    # 4. Feature Engineering - Financial & Inventory Metrics
    # Ensure numerical types
    df['Sales'] = df['Sales'].astype(float).round(2)
    df['Quantity'] = df['Quantity'].astype(int)
    df['Discount'] = df['Discount'].astype(float).round(2)
    df['Profit'] = df['Profit'].astype(float).round(2)
    
    # Derived Financial Metrics
    df['Unit_Price'] = (df['Sales'] / df['Quantity']).round(2)
    df['COGS'] = (df['Sales'] - df['Profit']).round(2)
    df['Unit_Cost'] = (df['COGS'] / df['Quantity']).round(2)
    df['Profit_Margin_%'] = np.where(df['Sales'] > 0, (df['Profit'] / df['Sales'] * 100).round(2), 0)

    # Shipping Duration / Lead Time (Days)
    df['Lead_Time_Days'] = (df['Ship Date'] - df['Order Date']).dt.days.clip(lower=0)

    # Simulated Inventory Metrics based on Product Category Demand
    # Calculate average daily sales per product to establish realistic stock levels
    product_demand = df.groupby('Product ID')['Quantity'].transform('sum')
    df['Stock_On_Hand'] = (product_demand * np.random.uniform(0.8, 1.5, len(df))).astype(int) + 10
    df['Safety_Stock'] = (df['Quantity'] * 1.5 + df['Lead_Time_Days'] * 2).astype(int)
    df['Reorder_Point'] = (df['Quantity'] + df['Safety_Stock']).astype(int)
    
    # Demand Status classification
    conditions = [
        (df['Quantity'] > df['Quantity'].quantile(0.85)),
        (df['Stock_On_Hand'] < df['Reorder_Point']),
    ]
    choices = ['High Demand', 'Stockout Risk']
    df['Demand_Status'] = np.select(conditions, choices, default='Normal Demand')

    print(f"Cleaned dataset shape: {df.shape}")
    print(f"Date range: {df['Order Date'].min().strftime('%Y-%m-%d')} to {df['Order Date'].max().strftime('%Y-%m-%d')}")
    print(f"Total Sales: ${df['Sales'].sum():,.2f}, Total Profit: ${df['Profit'].sum():,.2f}")
    
    # 5. Save Cleaned Dataset
    df.to_csv(clean_csv_path, index=False)
    print(f"Cleaned CSV saved to: {clean_csv_path}")

    # Save to Excel (first 10,000+ rows)
    with pd.ExcelWriter(clean_excel_path, engine='openpyxl') as writer:
        df.to_excel(writer, sheet_name='Cleaned_Sales_Data', index=False)
    print(f"Cleaned Excel saved to: {clean_excel_path}")

    print("=== Data Preprocessing Completed Successfully ===")

if __name__ == "__main__":
    run_preprocessing()
