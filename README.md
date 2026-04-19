# 🛒 E-Commerce Data Analytics Pipeline

## 📌 Project Overview

An end-to-end data engineering project that processes **99,441 real-world e-commerce transactions** from raw CSV files into a structured MySQL database, enabling comprehensive business analytics and data-driven decision making.

This project demonstrates the complete data pipeline workflow: **ingestion → cleaning → transformation → loading → analytics → optimization**.

---

## 🎯 Business Problem

E-commerce platforms generate massive amounts of transactional data across multiple sources (orders, customers, products, payments, reviews). This data needs to be:
- Cleaned and validated
- Structured for efficient querying
- Analyzed to derive actionable business insights

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Python 3.8+** | Data processing and transformation |
| **Pandas** | Data cleaning and manipulation |
| **MySQL 8.0** | Relational database for storage |
| **Google Colab** | Development environment |
| **MySQL Workbench** | Database management and querying |

---

## 📊 Dataset

**Source**: Brazilian E-Commerce Public Dataset (Olist)

**Size**: 
- 99,441 orders
- 112,650 order items
- 96,096 unique customers
- 32,951 products
- 103,886 payment records
- 99,224 reviews
- 8 CSV files

**Time Period**: 2016-2018

---

## 🏗️ Project Architecture
Raw CSV Files (8 sources)
↓
Data Ingestion (Python/Pandas)
↓
Data Cleaning & Validation
↓
Data Transformation
↓
MySQL Database (8 normalized tables)
↓
SQL Analytics & Business Insights
↓
Performance Optimization (Indexing)

---

## 🧹 Data Cleaning & Transformation

### Key Challenges Solved:

#### 1. **Data Type Issues**
- Converted 5 date columns from `object` to `datetime64`
- Fixed zip codes stored as integers (causing leading zero loss)
- Corrected column name typos (`lenght` → `length`)

#### 2. **Missing Values Handled**
orders.order_approved_at            → 160 nulls (failed payments)
orders.order_delivered_customer_date → 2,965 nulls (cancelled orders)
products.product_category_name       → 610 nulls (filled with 'unknown')
reviews.review_comment_message       → 58,247 nulls (customers skipped reviews)
**Strategy**: Business logic validation instead of blanket deletion

#### 3. **Duplicate Data**
- Removed **981,148 duplicate rows** from geolocation table (98% reduction!)
- Kept unique zip code entries only

#### 4. **Feature Engineering**
- Created `delivery_time_days` column by calculating difference between purchase and delivery dates
- Merged product category translations (Portuguese → English)

---

## 🗄️ Database Schema Design

### Normalized Relational Model (3NF)
customers ──< orders ──< order_items >── products
│              │
│              └── sellers
│
┌────┴─────┬──────────┐
│          │          │
payments   reviews   geolocation

**8 Tables with Foreign Key Constraints:**
- `customers` (99,441 rows)
- `orders` (99,441 rows)
- `order_items` (112,650 rows)
- `products` (32,951 rows)
- `sellers` (3,095 rows)
- `payments` (103,886 rows)
- `reviews` (99,224 rows)
- `geolocation` (19,015 rows)

---

## 📈 Key SQL Analytics Queries

### 1. Revenue Analysis
```sql
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value), 2) AS total_revenue,
    ROUND(AVG(payment_value), 2) AS avg_order_value
FROM payments;
```
**Result**: $15.4M total revenue, $160 average order value

---

### 2. Top Product Categories
```sql
SELECT 
    p.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;
```
**Insight**: Health & Beauty ($1.2M) and Watches ($1.1M) are top categories

---

### 3. Delivery Performance by State
```sql
SELECT 
    c.customer_state,
    ROUND(AVG(o.delivery_time_days), 2) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.delivery_time_days IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days;
```
**Insight**: SP (São Paulo) has fastest delivery (9.5 days), RR has slowest (31 days)

---

### 4. Customer Retention Analysis
```sql
SELECT 
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS returning_customers
FROM (
    SELECT customer_unique_id, COUNT(*) AS order_count
    FROM customers
    GROUP BY customer_unique_id
) subquery;
```
**Critical Finding**: Only **3.5% customer retention rate** → major business problem!

---

### 5. Payment Method Preferences
```sql
SELECT 
    payment_type,
    COUNT(*) AS transactions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM payments
GROUP BY payment_type;
```
**Result**: 
- Credit Card: 74%
- Boleto (bank slip): 19%
- Voucher: 6%

---

## ⚡ Performance Optimization

### Indexing Strategy

Created **5 strategic indexes** on high-cardinality join columns:

```sql
-- Critical JOIN optimizations
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_seller_id ON order_items(seller_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_reviews_order_id ON reviews(order_id);
```

### Performance Impact

**Query: Revenue by Product Category**
- **Before Index**: 0.054 seconds
- **After Index**: 0.037 seconds
- **Improvement**: **31.5% faster** ✅

**Query: Customer State Analysis**
- **Before Index**: 0.089 seconds
- **After Index**: 0.061 seconds
- **Improvement**: **31.4% faster** ✅

---

## 💡 Key Business Insights Discovered

| Insight | Impact |
|---------|--------|
| 🔴 **3.5% customer retention rate** | Major churn problem - need loyalty programs |
| 💳 **74% prefer credit cards** | Optimize payment gateway for cards |
| 📦 **12-day average delivery** | Delivery optimization needed for competitiveness |
| ⭐ **88% customers don't write reviews** | Incentivize review writing |
| 🏙️ **São Paulo = 42% of orders** | Geographic concentration risk |
| 📉 **2,965 cancelled orders** | Investigate cancellation reasons |

---

## 📁 Project Structure

```
ecommerce-analytics/
│
├── README.md                              # Project documentation
│
├── Cleaned-Data-set/                      # Processed CSV files
│   ├── cleaned_orders.csv
│   ├── cleaned_order_items.csv
│   ├── cleaned_customers.csv
│   ├── cleaned_products.csv
│   ├── cleaned_sellers.csv
│   ├── cleaned_payments.csv
│   ├── cleaned_reviews.csv
│   └── cleaned_geolocation.csv
│
├── Raw-Data-csv/                          # Original dataset files
│   ├── olist_orders_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_customers_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_sellers_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_geolocation_dataset.csv
│   └── product_category_name_translation.csv
│
├── E-commerce-Pipeline-Project.ipynb      # Google Colab notebook (data cleaning)
│
|── SQL-Query/                             # SQL scripts
   ├── 01_create_database.sql
   ├── 02_analytics_queries.sql
   └── 03_performance_indexing.sql


```

---

## 🚀 How to Reproduce This Project

### Prerequisites
```bash
Python 3.8+
MySQL 8.0+
Pandas library
```


---

## 📚 Skills Demonstrated

### Data Engineering
✅ ETL pipeline development  
✅ Data quality validation  
✅ Schema design (normalization)  
✅ Database optimization  
✅ Large dataset handling (100k+ rows)  

### SQL
✅ Complex JOINs (3+ tables)  
✅ Aggregations & GROUP BY  
✅ Window functions  
✅ Subqueries & CTEs  
✅ Performance tuning with indexes  

### Python
✅ Pandas data manipulation  
✅ DateTime handling  
✅ Missing value strategies  
✅ Data type conversions  
✅ CSV processing  

---

## 🎓 Lessons Learned

1. **Always validate nulls before deleting** → Saved 2,965 cancelled order records with valid business logic
2. **Encoding matters** → UTF-8-sig prevented special character issues in Portuguese text
3. **Indexes aren't free** → Strategic indexing on JOIN columns gives best ROI
4. **Data duplication is common** → 98% of geolocation data was duplicate
5. **Business context drives decisions** → 88% null reviews is normal user behavior, not data quality issue

---

## 🔮 Future Enhancements

- [ ] Add Python script for automated daily data refresh
- [ ] Build interactive dashboard using Power BI / Tableau
- [ ] Implement stored procedures for recurring queries
- [ ] Add data validation tests (Great Expectations)
- [ ] Create Apache Airflow DAG for pipeline orchestration
- [ ] Migrate to cloud (AWS RDS / Google Cloud SQL)

---

## 👤 Author

**Harsha Gurrala**  
📧 harshagurrala000@gmail.com
💼 [LinkedIn](https://www.linkedin.com/in/harsha-gurrala-8a7933315/)  
🐙 [GitHub](https://github.com/Harshagurrala)

---

## 📄 License

This project is for educational purposes. Dataset source: [Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

## 🙏 Acknowledgments

- Olist for providing the public dataset
- Kaggle for hosting the data
- Brazilian E-Commerce community

---

⭐ **If you found this project helpful, please consider giving it a star!**
