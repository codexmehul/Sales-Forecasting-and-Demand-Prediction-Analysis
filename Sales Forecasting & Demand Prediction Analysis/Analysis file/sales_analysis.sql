-- =============================================================================
-- SALES FORECASTING & DEMAND PREDICTION ANALYSIS - SQL SCRIPT
-- Retail Company Demand Planning & Inventory Optimization
-- Author: Data Analyst
-- Date: 2026-09-04
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SECTION 1: DATABASE SCHEMA & TABLE DEFINITION
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS cleaned_sales_data;

CREATE TABLE cleaned_sales_data (
    Row_ID INT PRIMARY KEY,
    Order_ID VARCHAR(50),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(50),
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country_Region VARCHAR(50),
    City VARCHAR(50),
    State_Province VARCHAR(50),
    Postal_Code VARCHAR(20),
    Region VARCHAR(50),
    Product_ID VARCHAR(50),
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(255),
    Sales DECIMAL(10,2),
    Quantity INT,
    Discount DECIMAL(4,2),
    Profit DECIMAL(10,2),
    Year INT,
    Month INT,
    Month_Name VARCHAR(10),
    Year_Month VARCHAR(10),
    Quarter VARCHAR(5),
    Day INT,
    Day_Of_Week VARCHAR(15),
    Is_Weekend INT,
    Week_Of_Year INT,
    Season VARCHAR(15),
    Unit_Price DECIMAL(10,2),
    COGS DECIMAL(10,2),
    Unit_Cost DECIMAL(10,2),
    Profit_Margin_Pct DECIMAL(6,2),
    Lead_Time_Days INT,
    Stock_On_Hand INT,
    Safety_Stock INT,
    Reorder_Point INT,
    Demand_Status VARCHAR(30)
);

-- -----------------------------------------------------------------------------
-- SECTION 2: DATA CLEANING & HYGIENE VERIFICATION
-- -----------------------------------------------------------------------------

-- 2.1 Total Row Count & Validation (Must be >= 10,000)
SELECT COUNT(*) AS total_records FROM cleaned_sales_data;

-- 2.2 Null Value Verification in Critical Columns
SELECT 
    COUNT(CASE WHEN Order_ID IS NULL THEN 1 END) AS null_order_ids,
    COUNT(CASE WHEN Order_Date IS NULL THEN 1 END) AS null_order_dates,
    COUNT(CASE WHEN Product_ID IS NULL THEN 1 END) AS null_product_ids,
    COUNT(CASE WHEN Sales IS NULL THEN 1 END) AS null_sales,
    COUNT(CASE WHEN Quantity IS NULL THEN 1 END) AS null_quantity
FROM cleaned_sales_data;

-- 2.3 Date Range & Temporal Coverage
SELECT 
    MIN(Order_Date) AS start_date,
    MAX(Order_Date) AS end_date,
    COUNT(DISTINCT Year) AS total_years,
    COUNT(DISTINCT Year_Month) AS total_months
FROM cleaned_sales_data;


-- -----------------------------------------------------------------------------
-- SECTION 3: HISTORICAL SALES TREND ANALYSIS (MONTHLY, YEARLY, WEEKLY)
-- -----------------------------------------------------------------------------

-- 3.1 Yearly Sales Performance & Growth
SELECT 
    Year,
    COUNT(DISTINCT Order_ID) AS total_orders,
    SUM(Quantity) AS total_units_sold,
    ROUND(SUM(Sales), 2) AS total_revenue,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(AVG(Profit_Margin_Pct), 2) AS avg_profit_margin_pct,
    ROUND(
        (SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY Year)) 
        / LAG(SUM(Sales)) OVER (ORDER BY Year) * 100, 2
    ) AS YoY_Revenue_Growth_Pct
FROM cleaned_sales_data
GROUP BY Year
ORDER BY Year;

-- 3.2 Monthly Sales & MoM Growth Analysis
SELECT 
    Year_Month,
    Year,
    Month,
    Month_Name,
    COUNT(DISTINCT Order_ID) AS total_orders,
    SUM(Quantity) AS total_units,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(
        (SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY Year_Month)) 
        / LAG(SUM(Sales)) OVER (ORDER BY Year_Month) * 100, 2
    ) AS MoM_Sales_Growth_Pct
FROM cleaned_sales_data
GROUP BY Year_Month, Year, Month, Month_Name
ORDER BY Year_Month;

-- 3.3 Day of Week & Weekend Sales Contribution
SELECT 
    Day_Of_Week,
    Is_Weekend,
    COUNT(DISTINCT Order_ID) AS order_count,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(AVG(Sales), 2) AS avg_order_value
FROM cleaned_sales_data
GROUP BY Day_Of_Week, Is_Weekend
ORDER BY total_sales DESC;


-- -----------------------------------------------------------------------------
-- SECTION 4: SEASONAL PATTERNS & PEAK DEMAND ANALYSIS
-- -----------------------------------------------------------------------------

-- 4.1 Monthly Seasonality Index Calculation
WITH MonthlyAgg AS (
    SELECT 
        Month,
        Month_Name,
        AVG(Monthly_Sales) AS avg_monthly_sales
    FROM (
        SELECT Year, Month, Month_Name, SUM(Sales) AS Monthly_Sales
        FROM cleaned_sales_data
        GROUP BY Year, Month, Month_Name
    ) sub
    GROUP BY Month, Month_Name
),
OverallAvg AS (
    SELECT AVG(Monthly_Sales) AS overall_avg_sales
    FROM (
        SELECT Year, Month, SUM(Sales) AS Monthly_Sales
        FROM cleaned_sales_data
        GROUP BY Year, Month
    ) sub2
)
SELECT 
    m.Month,
    m.Month_Name,
    ROUND(m.avg_monthly_sales, 2) AS avg_monthly_sales,
    ROUND(o.overall_avg_sales, 2) AS overall_avg_sales,
    ROUND(m.avg_monthly_sales / o.overall_avg_sales, 4) AS Seasonality_Index,
    CASE 
        WHEN (m.avg_monthly_sales / o.overall_avg_sales) >= 1.15 THEN 'Peak Season (High Demand)'
        WHEN (m.avg_monthly_sales / o.overall_avg_sales) <= 0.85 THEN 'Off-Peak Season (Low Demand)'
        ELSE 'Normal Demand'
    END AS Demand_Season_Classification
FROM MonthlyAgg m, OverallAvg o
ORDER BY m.Month;

-- 4.2 Quarterly Demand Patterns by Category
SELECT 
    Category,
    Quarter,
    SUM(Quantity) AS total_units_sold,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Sales) * 100.0 / SUM(SUM(Sales)) OVER(PARTITION BY Category), 2) AS category_quarter_share_pct
FROM cleaned_sales_data
GROUP BY Category, Quarter
ORDER BY Category, Quarter;


-- -----------------------------------------------------------------------------
-- SECTION 5: PRODUCT & CATEGORY PERFORMANCE (ABC ANALYSIS)
-- -----------------------------------------------------------------------------

-- 5.1 Category & Sub-Category Sales Ranking
SELECT 
    Category,
    Sub_Category,
    COUNT(DISTINCT Product_ID) AS unique_products,
    SUM(Quantity) AS total_units_sold,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(AVG(Profit_Margin_Pct), 2) AS avg_margin_pct
FROM cleaned_sales_data
GROUP BY Category, Sub_Category
ORDER BY total_sales DESC;

-- 5.2 Top 10 High Demand Products (Future Revenue Drivers)
SELECT 
    Product_ID,
    Product_Name,
    Category,
    Sub_Category,
    SUM(Quantity) AS total_units_demanded,
    ROUND(SUM(Sales), 2) AS total_revenue_generated,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(AVG(Discount), 2) AS avg_discount_given
FROM cleaned_sales_data
GROUP BY Product_ID, Product_Name, Category, Sub_Category
ORDER BY total_revenue_generated DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- SECTION 6: BASIC SALES FORECASTING (3-MONTH MOVING AVERAGE & TREND)
-- -----------------------------------------------------------------------------

WITH MonthlySales AS (
    SELECT 
        Year_Month,
        ROW_NUMBER() OVER (ORDER BY Year_Month) AS month_seq,
        SUM(Sales) AS actual_sales
    FROM cleaned_sales_data
    GROUP BY Year_Month
)
SELECT 
    Year_Month,
    month_seq,
    ROUND(actual_sales, 2) AS actual_sales,
    ROUND(
        AVG(actual_sales) OVER (
            ORDER BY month_seq 
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ), 2
    ) AS moving_avg_3m_forecast,
    ROUND(
        ABS(actual_sales - AVG(actual_sales) OVER (
            ORDER BY month_seq 
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        )), 2
    ) AS forecast_error_mae
FROM MonthlySales
ORDER BY month_seq;


-- -----------------------------------------------------------------------------
-- SECTION 7: DEMAND PLANNING & INVENTORY OPTIMIZATION QUERIES
-- -----------------------------------------------------------------------------

-- 7.1 Safety Stock & Reorder Point Requirements by Product Category
SELECT 
    Category,
    COUNT(DISTINCT Product_ID) AS product_count,
    ROUND(AVG(Lead_Time_Days), 1) AS avg_lead_time_days,
    ROUND(AVG(Quantity), 1) AS avg_daily_order_qty,
    ROUND(SUM(Safety_Stock), 0) AS total_safety_stock_required,
    ROUND(SUM(Reorder_Point), 0) AS total_reorder_point_threshold,
    SUM(Stock_On_Hand) AS current_stock_on_hand,
    CASE 
        WHEN SUM(Stock_On_Hand) < SUM(Reorder_Point) THEN 'CRITICAL: Reorder Immediately'
        ELSE 'Stock Level Adequate'
    END AS Replenishment_Action
FROM cleaned_sales_data
GROUP BY Category;

-- 7.2 Stockout Risk Alerts by Sub-Category
SELECT 
    Sub_Category,
    COUNT(CASE WHEN Demand_Status = 'Stockout Risk' THEN 1 END) AS stockout_risk_count,
    COUNT(CASE WHEN Demand_Status = 'High Demand' THEN 1 END) AS high_demand_count,
    COUNT(*) AS total_transactions,
    ROUND(
        COUNT(CASE WHEN Demand_Status = 'Stockout Risk' THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS stockout_risk_rate_pct
FROM cleaned_sales_data
GROUP BY Sub_Category
ORDER BY stockout_risk_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- SECTION 8: SOLUTIONS TO THE 5 BUSINESS QUESTIONS
-- -----------------------------------------------------------------------------

-- QUESTION 1: Which months have the highest sales?
SELECT 
    Month_Name,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(AVG(Sales), 2) AS avg_sales_per_order,
    DENSE_RANK() OVER (ORDER BY SUM(Sales) DESC) AS sales_rank
FROM cleaned_sales_data
GROUP BY Month_Name
ORDER BY total_sales DESC;

-- QUESTION 2: Is there any seasonal pattern in sales?
SELECT 
    Season,
    Quarter,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Sales) * 100.0 / (SELECT SUM(Sales) FROM cleaned_sales_data), 2) AS revenue_share_pct
FROM cleaned_sales_data
GROUP BY Season, Quarter
ORDER BY total_sales DESC;

-- QUESTION 3: What is the overall sales trend (increasing or decreasing)?
SELECT 
    Year,
    ROUND(SUM(Sales), 2) AS yearly_sales,
    ROUND(
        (SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY Year)) 
        / LAG(SUM(Sales)) OVER (ORDER BY Year) * 100, 2
    ) AS yearly_growth_pct,
    CASE 
        WHEN SUM(Sales) > LAG(SUM(Sales)) OVER (ORDER BY Year) THEN 'Increasing Trend'
        WHEN SUM(Sales) < LAG(SUM(Sales)) OVER (ORDER BY Year) THEN 'Decreasing Trend'
        ELSE 'Baseline Year'
    END AS Trend_Direction
FROM cleaned_sales_data
GROUP BY Year
ORDER BY Year;

-- QUESTION 4: Which products are expected to have high demand in the future?
SELECT 
    Product_Name,
    Category,
    Sub_Category,
    SUM(Quantity) AS total_units_sold,
    ROUND(SUM(Sales), 2) AS total_sales,
    'High Demand (Category A)' AS Projected_Future_Demand
FROM cleaned_sales_data
GROUP BY Product_Name, Category, Sub_Category
ORDER BY total_sales DESC
LIMIT 15;

-- QUESTION 5: How can the company improve demand planning?
-- Strategic query evaluating category lead times, reorder thresholds, and demand volatility
SELECT 
    Category,
    ROUND(AVG(Lead_Time_Days), 2) AS avg_supplier_lead_time_days,
    ROUND(AVG(Discount), 4) * 100 AS avg_promo_discount_pct,
    ROUND(SUM(Safety_Stock), 0) AS recommended_safety_stock,
    ROUND(SUM(Reorder_Point), 0) AS recommended_reorder_point,
    'Implement Dynamic Reorder Buffer & Align Marketing Promos with Stock Levels' AS Demand_Planning_Strategy
FROM cleaned_sales_data
GROUP BY Category;

-- =============================================================================
-- END OF SQL SCRIPT
-- =============================================================================
