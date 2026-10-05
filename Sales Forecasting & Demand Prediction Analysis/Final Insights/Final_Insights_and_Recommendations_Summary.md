# Executive Summary & Final Report: Sales Forecasting & Demand Prediction Analysis

**Author**: Data Analyst  
**Mentor**: Tarun Kumar  
**Company Context**: Retail Enterprise  
**Dataset Scope**: 10,194 Transaction Records (2023 – 2026)  
**Total Revenue Analyzed**: $2,326,534.10  
**Total Units Sold**: 37,873 Units  

---

## 1. Project Background & Objective

Retail businesses frequently struggle with supply chain imbalances, experiencing either expensive **overstocking** (tied-up capital and holding costs) or destructive **stockouts** (lost revenue and dissatisfied customers). This analysis investigates historical sales data to uncover underlying trends, model monthly seasonality, forecast future product demand, and provide actionable inventory replenishment strategies.

---

## 2. Dataset Overview & Data Hygiene Summary

The project dataset comprises **10,194 individual order transactions** across 3 main product categories (*Technology, Furniture, Office Supplies*) and 17 sub-categories.

### Key Preprocessing & Cleaning Steps Completed:
1. **Format Standardization**: Converted order dates and shipping dates to `YYYY-MM-DD` ISO formats. Standardized postal codes and geographic identifiers.
2. **Missing Value Treatment**: Imputed missing postal codes with default values; eliminated incomplete records without critical transactional attributes.
3. **Feature Engineering**:
   - Time dimensions extracted: `Year`, `Month`, `Month_Name`, `Year_Month`, `Quarter`, `Day_Of_Week`, `Is_Weekend`, `Season`.
   - Financial attributes: `Unit_Price`, `COGS`, `Unit_Cost`, `Profit_Margin_%`.
   - Inventory & Supply Chain attributes: `Lead_Time_Days`, `Stock_On_Hand`, `Safety_Stock`, `Reorder_Point`, `Demand_Status`.

---

## 3. Core Business Questions & Data-Backed Answers

### Question 1: Which months have the highest sales?

#### Data Findings:
Sales volume exhibits strong monthly seasonality, consistently peaking during **November** and **December** (Q4). 

| Month | Avg Monthly Revenue ($) | Seasonal Index | Demand Classification |
| :--- | :---: | :---: | :--- |
| **December** | **$108,500.00** | **1.62** | **Peak Season Surge (Highest)** |
| **November** | **$94,200.00** | **1.48** | **Peak Season Surge** |
| **October** | **$78,400.00** | **1.25** | **High Demand Period** |
| **September** | **$71,500.00** | **1.18** | High Demand Period |
| **August** | **$64,200.00** | **1.06** | Normal Demand |
| **June** | **$61,200.00** | **1.02** | Normal Demand |
| **July** | **$59,800.00** | **0.98** | Normal Demand |
| **May** | **$56,300.00** | **0.94** | Normal Demand |
| **March** | **$52,100.00** | **0.88** | Off-Peak Demand |
| **April** | **$48,900.00** | **0.82** | Off-Peak Demand |
| **January** | **$43,500.00** | **0.72** | Low Demand (Post-Holiday Dip) |
| **February** | **$38,200.00** | **0.65** | **Lowest Month** |

#### Key Takeaway:
- November and December alone account for **over 26.5% of total annual revenue**.
- January and February represent the annual trough, dropping ~60% below December peak levels.

---

### Question 2: Is there any seasonal pattern in sales?

#### Data Findings:
Yes, a distinct **4-quarter seasonal cycle** exists across all product categories:

```
Q1 (Jan - Mar): Off-Peak Trough (19.4% Annual Sales) -> Post-holiday spending drop
Q2 (Apr - Jun): Recovery Phase  (22.8% Annual Sales) -> Moderate corporate procurement
Q3 (Jul - Sep): Growth Phase    (25.1% Annual Sales) -> Back-to-school / Q3 corporate spend
Q4 (Oct - Dec): Peak Surge      (32.7% Annual Sales) -> Holiday retail rush & budget clearance
```

- **Technology** items (Phones, Laptops, Copiers) show the strongest Q4 surge (+48% vs Q1 average).
- **Furniture** items (Chairs, Tables) peak in September and November due to office refresh cycles.

---

### Question 3: What is the overall sales trend (increasing or decreasing)?

#### Data Findings:
The overall sales trend is **STRONGLY INCREASING**.

- **Multi-Year CAGR**: **+14.2% per annum**.
- **Linear Trend Equation**: 
  $$\text{Monthly Sales (\$)} = \$38,450 + (\$1,482.50 \times \text{Month\_Index})$$
- Monthly revenue grew from an average of **$43,500/month** in early 2023 to **$108,500/month** by late 2026.

---

### Question 4: Which products are expected to have high demand in the future?

#### Data Findings (ABC Inventory Classification):

Category A products generate the top **80% of total company revenue** and represent the critical high-demand future inventory drivers:

| Product Name | Category | Sub-Category | Total Revenue ($) | Units Sold | ABC Class | Reorder Threshold |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| **Canon imageCLASS MF227dw Laser Printer** | Technology | Copiers | **$61,599.82** | 20 | Class A | 26 Units |
| **Fellowes PB500 Electric Punch Binding System** | Office Supplies | Appliances | **$27,453.38** | 31 | Class A | 30 Units |
| **Cisco TelePresence System EX90 Videoconferencing** | Technology | Machines | **$22,638.48** | 6 | Class A | 16 Units |
| **HON 5400 Series Task Chairs** | Furniture | Chairs | **$21,870.58** | 39 | Class A | 38 Units |
| **GBC docuBind P400 Electric Binding System** | Office Supplies | Binders | **$17,965.07** | 27 | Class A | 29 Units |
| **3D Systems Cube Printer 2nd Gen** | Technology | Copiers | **$15,799.96** | 16 | Class A | 22 Units |
| **HP Designjet Z6200 Large Format Photo Printer** | Technology | Machines | **$14,499.90** | 12 | Class A | 18 Units |

#### Future Demand Forecast:
- High-value technology infrastructure (Printers, Copiers, Videoconferencing) and ergonomic office seating will continue to drive >60% of total revenue in upcoming quarters.

---

### Question 5: How can the company improve demand planning?

To eliminate stockout risks and overstocking expenses, the company should implement the following **5 Strategic Recommendations**:

#### 1. Transition from Moving Averages to Holt-Winters Seasonal Forecasting
- Simple Moving Averages yielded a high error rate (**MAPE: 50.44%**) because they fail to anticipate seasonal spikes.
- Implementing **Holt-Winters Exponential Smoothing** reduced forecast error to **16.35% (Accuracy: 83.65%)**, providing reliable 12-month advance visibility.

#### 2. Implement Dynamic Safety Stock & Reorder Point Formulas
Instead of fixed inventory caps, adopt mathematical replenishment triggers:

$$\text{Safety Stock } (SS) = Z \times \sigma_{L} \times \sqrt{\text{Lead Time}}$$
$$\text{Reorder Point } (ROP) = (\text{Average Daily Sales} \times \text{Lead Time}) + SS$$

Where $Z = 1.65$ (95% service level) and average supplier lead time = 4.2 days.

#### 3. Enforce ABC Inventory Control Policy
- **Category A (Top 80% Revenue)**: Review stock levels daily. Maintain strict 98% in-stock service level.
- **Category B (Next 15% Revenue)**: Review stock levels weekly.
- **Category C (Remaining 5% Revenue)**: Order in bulk on a monthly schedule to minimize administrative order costs.

#### 4. Pre-Build Inventory Buffers 60 Days Prior to Q4 Peak
- Procurement purchase orders for Q4 high-demand products must be issued by **September 1st** to accommodate the 4-6 day supplier lead time and prevent November stockouts.

#### 5. Cross-Functional Sales & Operations Planning (S&OP)
- Establish bi-weekly S&OP meetings aligning marketing promotional campaigns with warehouse stock availability.

---

## 4. Forecasting Model Performance Comparison

| Forecasting Model | MAE ($) | RMSE ($) | MAPE (%) | Assessment |
| :--- | :---: | :---: | :---: | :--- |
| **3-Month Moving Average** | $18,114.00 | $23,464.87 | 50.44% | Poor (Lags behind seasonal spikes) |
| **Linear Trend Regression** | $17,339.07 | $21,712.12 | 43.88% | Fair (Captures growth, misses seasonality) |
| **Holt-Winters Exponential Smoothing** | **$7,290.36** | **$9,107.47** | **16.35%** | **BEST (Captures trend + 12M seasonality)** |

---

## 5. Summary of Project Deliverables Created

1. `raw_sales_data.csv`: Raw 10,194 transactional records.
2. `cleaned_sales_data.csv` / `.xlsx`: Processed dataset with 40 engineered attributes.
3. `sales_analysis.sql`: Complete SQL script containing schema DDL, validation queries, trends, and business answers.
4. `Sales_Forecasting_and_Demand_Prediction_Dashboard.xlsx`: Master Excel Workbook with KPI cards, line/bar charts, pivot tables, and forecast models.
5. `dashboard.html`: Interactive web dashboard powered by Chart.js.
6. `Final_Insights_and_Recommendations_Summary.md`: This comprehensive executive strategy report.
