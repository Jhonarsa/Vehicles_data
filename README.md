# Vehicle Data Cleaning Project

## 📌 Overview  
This project simulates a **real-world data cleaning process** applied to a vehicle dataset.  
Although the dataset is simulated for confidentiality reasons, the **data quality issues** introduced (invalid number of doors, unrealistic engine displacements, inconsistencies between `model_year` and `registration_date`) mirror **real challenges** I have faced in professional environments.  

The goal is to demonstrate advanced **SQL-based data cleaning techniques**, including validation rules, mode imputation, and business-rule-based corrections.  

The project also includes **visualization dashboards in Tableau** to highlight the impact of data cleaning on business insights.  

---

## 🗂 Database Schema  
The schema models a relational vehicle registration system, including:  

- **Brands** (`brands`)  
- **Lines** (`lines_name`)  
- **Versions** (`versions`)  
- **Body types** (`body_types`)  
- **Vehicle classes** (`vehicle_classes`)  
- **Cities** (`cities`)  
- **Service modes** (`service_mode`)  
- **Vehicle statuses** (`vehicle_statuses`)  
- **Vehicles** (`vehicles`)  

👉 Full schema definition can be found here: [`/scripts/Schema_script.sql`](./scripts/Schema_script.sql).  

---

## 🧹 Data Cleaning Workflow  

Data cleaning was applied step by step using SQL (`/scripts/Cleaning_data.sql`), focusing on variables commonly affected by inconsistencies in real-world datasets:  

1. **General Validations**  
   - Ensured referential integrity.  
   - Validated that categorical values (classes, brands, body types, etc.) matched master tables.  

2. **Number of Doors (`num_doors`)**  
   - Motorcycles → always `0`.  
   - Cars & Pickups → valid range `[2..5]`.  
   - Trucks → valid range `[1..4]`.  
   - Out-of-range or null values replaced with the **mode**, using a fallback hierarchy:  
     1. `(brand, line, version, body_type)`  
     2. `(vehicle_class, body_type)`  
     3. `(vehicle_class)`  

3. **Engine Displacement (`engine_displacement_cc`)**  
   - Typical engine displacement calculated per `(class, brand, line)`.  
   - Class ranges defined:  
     - Car → `[800..3000]`  
     - Pickup → `[2000..5000]`  
     - Truck → `[4000..15000]`  
     - Motorcycle → `[80..1500]`  
   - Special case: if motorcycle’s typical engine falls within `[80..800]`, the valid range narrows to `[80..800]`.  
   - Out-of-range values updated with the **most typical engine displacement** for the group.  

4. **Model Year (`model_year`)**  
   - `registration_date` is assumed to be reliable (system-generated).  
   - Valid ranges derived per `(vehicle_class, brand, line, version)` using only records where `model_year = year(registration_date)`.  
   - Updates applied when:  
     - `abs(model_year - year(registration_date)) > 2`, or  
     - `model_year > current year + 1`,  
     - and `year(registration_date)` falls within the valid range.  

---

## 🛠 Tools & Skills Demonstrated  

- **SQL (MySQL 8)**  
  - Joins, subqueries, window functions, CTEs  
  - Conditional updates with business rules  
- **Data Quality Techniques**  
  - Mode imputation with fallback hierarchies  
  - Range validation by category  
  - Cross-variable consistency checks  
- **Documentation & Communication**  
  - Clear step-by-step documentation of data cleaning workflow  
- **Visualization (Tableau)**  
  - Impact of data cleaning on distributions and business KPIs  

---

## 📊 Tableau Dashboards  

Dashboards built in **Tableau** include:  

- **Before vs After Cleaning** → Distribution of `engine_displacement_cc`, `num_doors`, and `model_year`.  
- **Data Quality Impact** → Percentage of invalid records corrected.  
- **Vehicle Insights** → Breakdown by brand, class, and city with cleaned data.  

---

## ℹ️ About the Data  

The dataset is **simulated** for confidentiality reasons.  
However, the issues introduced (invalid doors, unrealistic engine displacements, inconsistent model years) reflect **real scenarios** I have encountered in professional projects.  

This ensures the project remains portfolio-safe while demonstrating **realistic data cleaning challenges**.  

---

## 📂 Repository Structure  

```text
├── scripts/
│   ├── Schema_script.sql      # Database schema creation and relationships
│   ├── Cleaning_data.sql      # Step-by-step data cleaning queries
│
├── data/                      # Raw CSV files used for database loading
│   ├── cities.csv
│   ├── brands.csv
│   ├── body_types.csv
│   ├── service_modes.csv
│   ├── vehicle_classes.csv
│   ├── lines.csv
│   ├── versions.csv
│   ├── vehicle_statuses.csv
│   ├── vehicles.csv
│
├── dashboards/                # Tableau workbook and exports
│
└── README.md                  # Project documentation

```

## ✅ Results & Learnings  

- Reduced invalid values in key variables (`num_doors`, `engine_displacement_cc`, `model_year`) to **0%**.  
- Applied **business-rule-driven corrections** to ensure data consistency.  
- Reinforced advanced SQL knowledge (**CTEs**, **window functions**, **conditional updates**).  
- Demonstrated ability to handle **realistic data quality issues** in vehicle registration datasets.  
- Showcased end-to-end workflow: from schema design → data cleaning → documentation → visualization.  
