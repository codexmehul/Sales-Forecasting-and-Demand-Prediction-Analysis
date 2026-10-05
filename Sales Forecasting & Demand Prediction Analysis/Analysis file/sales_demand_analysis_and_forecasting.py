import pandas as pd
import numpy as np
import os
from statsmodels.tsa.holtwinters import ExponentialSmoothing

def run_analysis_and_forecasting():
    print("=== Starting Time Series Demand Analysis & Forecasting ===")
    
    clean_csv_path = "cleaned_sales_data.csv"
    if not os.path.exists(clean_csv_path):
        raise FileNotFoundError(f"{clean_csv_path} not found. Run preprocessing first.")
        
    df = pd.read_csv(clean_csv_path)
    df['Order Date'] = pd.to_datetime(df['Order Date'])
    
    # -------------------------------------------------------------
    # 1. Monthly Time Series Aggregation
    # -------------------------------------------------------------
    monthly_df = df.groupby('Year_Month').agg(
        Total_Sales=('Sales', 'sum'),
        Total_Quantity=('Quantity', 'sum'),
        Total_Profit=('Profit', 'sum'),
        Order_Count=('Order ID', 'nunique'),
        Avg_Order_Value=('Sales', 'mean')
    ).reset_index()
    
    monthly_df = monthly_df.sort_values(by='Year_Month').reset_index(drop=True)
    monthly_df['Month_Index'] = range(1, len(monthly_df) + 1)
    
    # MoM Growth Rate (%)
    monthly_df['Sales_MoM_Growth_%'] = monthly_df['Total_Sales'].pct_change() * 100
    
    # Extract Month Name and Year for Seasonality Index
    monthly_df['Year'] = monthly_df['Year_Month'].str[:4].astype(int)
    monthly_df['Month_Num'] = monthly_df['Year_Month'].str[5:].astype(int)
    
    overall_mean_sales = monthly_df['Total_Sales'].mean()
    month_avg = monthly_df.groupby('Month_Num')['Total_Sales'].mean()
    seasonality_index = (month_avg / overall_mean_sales).to_dict()
    
    monthly_df['Seasonal_Index'] = monthly_df['Month_Num'].map(seasonality_index)
    
    # -------------------------------------------------------------
    # 2. Time Series Forecasting Models
    # -------------------------------------------------------------
    # A. 3-Month Moving Average
    monthly_df['MA_3_Forecast'] = monthly_df['Total_Sales'].shift(1).rolling(window=3).mean()
    
    # B. Linear Trend Model: Sales = alpha + beta * Month_Index
    X = monthly_df['Month_Index'].values
    Y = monthly_df['Total_Sales'].values
    slope, intercept = np.polyfit(X, Y, 1)
    
    monthly_df['Linear_Trend_Forecast'] = intercept + slope * monthly_df['Month_Index']
    
    # C. Holt-Winters / Exponential Smoothing (Additive Seasonality, seasonal_periods=12)
    try:
        model = ExponentialSmoothing(
            Y, 
            trend='add', 
            seasonal='add', 
            seasonal_periods=12,
            initialization_method="estimated"
        )
        fitted_model = model.fit()
        monthly_df['Holt_Winters_Forecast'] = fitted_model.fittedvalues
        
        # 12-Month Future Prediction using Holt-Winters
        future_hw = fitted_model.forecast(12)
    except Exception as e:
        print(f"Holt-Winters warning: {e}. Falling back to Linear Trend * Seasonal Index.")
        monthly_df['Holt_Winters_Forecast'] = monthly_df['Linear_Trend_Forecast'] * monthly_df['Seasonal_Index']
        future_indices = np.arange(len(monthly_df) + 1, len(monthly_df) + 13)
        future_months = [(monthly_df['Month_Num'].iloc[-1] + i - 1) % 12 + 1 for i in range(1, 13)]
        future_hw = (intercept + slope * future_indices) * np.array([seasonality_index[m] for m in future_months])

    # Forecast Error Evaluation (for historical overlapping periods, index >= 12)
    eval_df = monthly_df.dropna(subset=['MA_3_Forecast', 'Holt_Winters_Forecast']).copy()
    
    def calculate_metrics(actual, pred):
        mae = np.mean(np.abs(actual - pred))
        rmse = np.sqrt(np.mean((actual - pred)**2))
        mape = np.mean(np.abs((actual - pred) / actual)) * 100
        return mae, rmse, mape

    mae_ma, rmse_ma, mape_ma = calculate_metrics(eval_df['Total_Sales'], eval_df['MA_3_Forecast'])
    mae_lin, rmse_lin, mape_lin = calculate_metrics(eval_df['Total_Sales'], eval_df['Linear_Trend_Forecast'])
    mae_hw, rmse_hw, mape_hw = calculate_metrics(eval_df['Total_Sales'], eval_df['Holt_Winters_Forecast'])

    accuracy_metrics_df = pd.DataFrame([
        {'Model': '3-Month Moving Average', 'MAE': round(mae_ma, 2), 'RMSE': round(rmse_ma, 2), 'MAPE_%': round(mape_ma, 2)},
        {'Model': 'Linear Trend Regression', 'MAE': round(mae_lin, 2), 'RMSE': round(rmse_lin, 2), 'MAPE_%': round(mape_lin, 2)},
        {'Model': 'Holt-Winters Exponential Smoothing', 'MAE': round(mae_hw, 2), 'RMSE': round(rmse_hw, 2), 'MAPE_%': round(mape_hw, 2)}
    ])
    
    print("\n--- Model Accuracy Metrics ---")
    print(accuracy_metrics_df)

    # -------------------------------------------------------------
    # 3. Generate 12-Month Future Demand Forecast Table
    # -------------------------------------------------------------
    last_ym = monthly_df['Year_Month'].iloc[-1]
    last_year, last_month = int(last_ym[:4]), int(last_ym[5:])
    
    future_dates = []
    curr_year, curr_month = last_year, last_month
    for i in range(1, 13):
        curr_month += 1
        if curr_month > 12:
            curr_month = 1
            curr_year += 1
        future_dates.append(f"{curr_year}-{curr_month:02d}")
        
    future_indices = np.arange(len(monthly_df) + 1, len(monthly_df) + 13)
    future_linear = intercept + slope * future_indices
    
    future_df = pd.DataFrame({
        'Year_Month': future_dates,
        'Month_Index': future_indices,
        'Linear_Forecast': np.round(future_linear, 2),
        'Holt_Winters_Forecast': np.round(future_hw, 2),
        'Forecast_Status': 'Projected'
    })
    
    # -------------------------------------------------------------
    # 4. Category & Product Demand Analysis (ABC Classification)
    # -------------------------------------------------------------
    prod_summary = df.groupby(['Category', 'Sub-Category', 'Product Name']).agg(
        Total_Revenue=('Sales', 'sum'),
        Total_Units_Sold=('Quantity', 'sum'),
        Total_Profit=('Profit', 'sum'),
        Avg_Discount=('Discount', 'mean'),
        Avg_Lead_Time=('Lead_Time_Days', 'mean'),
        Avg_Safety_Stock=('Safety_Stock', 'mean'),
        Avg_Reorder_Point=('Reorder_Point', 'mean')
    ).reset_index()
    
    # Sort by total revenue descending
    prod_summary = prod_summary.sort_values(by='Total_Revenue', ascending=False).reset_index(drop=True)
    
    # Calculate Cumulative Revenue Share %
    total_rev = prod_summary['Total_Revenue'].sum()
    prod_summary['Cum_Revenue'] = prod_summary['Total_Revenue'].cumsum()
    prod_summary['Cum_Revenue_%'] = (prod_summary['Cum_Revenue'] / total_rev) * 100
    
    # ABC Classification
    def abc_classify(cum_pct):
        if cum_pct <= 80:
            return 'A (High Value)'
        elif cum_pct <= 95:
            return 'B (Medium Value)'
        else:
            return 'C (Low Value)'
            
    prod_summary['ABC_Class'] = prod_summary['Cum_Revenue_%'].apply(abc_classify)

    # Category Summary
    cat_summary = df.groupby('Category').agg(
        Total_Sales=('Sales', 'sum'),
        Total_Quantity=('Quantity', 'sum'),
        Total_Profit=('Profit', 'sum'),
        Avg_Profit_Margin=('Profit_Margin_%', 'mean')
    ).reset_index().sort_values(by='Total_Sales', ascending=False)

    # -------------------------------------------------------------
    # 5. Export Analytical Tables
    # -------------------------------------------------------------
    monthly_df.to_csv("monthly_sales_and_forecast.csv", index=False)
    future_df.to_csv("future_12m_demand_forecast.csv", index=False)
    prod_summary.to_csv("product_demand_ranking.csv", index=False)
    cat_summary.to_csv("category_performance.csv", index=False)
    accuracy_metrics_df.to_csv("forecasting_accuracy_metrics.csv", index=False)
    
    print("\n=== Time Series Analysis & Demand Forecasting Completed Successfully ===")

if __name__ == "__main__":
    run_analysis_and_forecasting()
