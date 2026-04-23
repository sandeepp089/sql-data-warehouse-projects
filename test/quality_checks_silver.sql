/*
================================================================================
Quality Checks
================================================================================

Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' schemas. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.

================================================================================
*/

-- ===================================================
-- Checking 'silver.crm_cust_info'
-- ===================================================

-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT 
* 
FROM silver.crm_cust_info;

SELECT 
cst_id, COUNT(*) 
FROM silver.crm_cust_info
GROUP BY cst_id 
HAVING COUNT(*) > 1 OR cst_id IS NULL

-- Check for unwanted Spaces
-- Expectation: No Results
SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

SELECT * FROM silver.crm_cust_info


-- ===================================================
-- Checking 'silver.crm_prd_info'
-- ===================================================

-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT * 
FROM silver.crm_prd_info  


SELECT prd_id, COUNT(*)
FROM silver.crm_prd_info  
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL


-- Check for unwanted Spaces
-- Expectation: No Results

SELECT 
prd_nm
FROM silver.crm_prd_info  
WHERE TRIM(prd_nm) != prd_nm

-- Check for NULLS or Negative Numbers
-- Expectation: No Results

SELECT prd_cost 
FROM silver.crm_prd_info 
WHERE prd_cost IS NULL OR prd_cost < 0

-- Data Standardization & Consistencyy
SELECT DISTINCT prd_line FROM silver.crm_prd_info  

-- Check for Invalid Date Orders
SELECT
*
FROM silver.crm_prd_info  
WHERE prd_end_dt < prd_start_dt

SELECT * FROM silver.crm_prd_info


-- ===================================================
-- Checking 'silver.crm_sales_details'
-- ===================================================

-- Check For Nulls or unwanted data
-- Expectation: No Result

SELECT 
NULLIF(sls_due_dt,0) sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101

--Check For Negative, Zeros, Nulls
-- Business Rules 
-- Sales = Quantity * Price 
-- Negative, Zeros, Nulls are Not Allowed!

SELECT 
sls_sales, 
sls_quantity,
sls_price
FROM
silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price


SELECT 
*
FROM
silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt



-- ===================================================
-- Checking 'silver.erp_cust_az12'
-- ===================================================

-- Check For Nulls or unwanted data
-- Expectation: No Result

SELECT 
cid,
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4, LEN(cid))
	 ELSE cid
END AS cid,
bdate,
gen
FROM silver.erp_cust_az12
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info)

-- Check for very old customers
-- Check for birthdays in the future
SELECT 
TRY_CONVERT(DATE, bdate,105) AS bdate
FROM silver.erp_cust_az12
WHERE TRY_CONVERT(DATE, bdate)
 < '1924-01-01' OR  TRY_CONVERT(DATE, bdate) > GETDATE()

 -- Check unwanted data
 SELECT DISTINCT gen,
 CASE 
	  WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	  WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	  ELSE 'n/a'
END AS gen
 FROM bronze.erp_cust_az12


 
-- ===================================================
-- Checking 'silver.erp_loc_a101'
-- ===================================================

-- Check For Nulls or unwanted data
-- Expectation: No Result
 SELECT
 REPLACE(cid,'-','') AS cid
 FROM bronze.erp_loc_a101
 WHERE REPLACE(cid,'-','') NOT IN (SELECT cst_key FROM silver.crm_cust_info)
 SELECT cst_key FROM silver.crm_cust_info

-- Data Standadization & Consistency
SELECT
DISTINCT cntry AS old_cntry,
CASE WHEN TRIM(cntry) IN ('US', 'USA', 'UNITED STATES') THEN 'United States' 
	 WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 WHEN cntry = '' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101
 
 SELECT DISTINCT cntry FROM silver.erp_loc_a101


 -- ===================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ===================================================

 SELECT 
*
 FROM silver.erp_px_cat_g1v2


 SELECT DISTINCT
 maintenance
 FROM bronze.erp_px_cat_g1v2
