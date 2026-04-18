# Smart Invoice Validation System
### Simulated SAP Procure-to-Pay (P2P) Environment

**Author:** Harsh Raj  
**Roll Number:** 2330162  
**Program:** B.Tech - Electronics & Computer Science (ECSc.)  
**Batch:** 2023–2027  

---

## 📌 Project Overview

This project implements a **Smart Invoice Validation System** in ABAP that simulates the SAP Procure-to-Pay (P2P) process. It performs **3-way matching** of Purchase Orders, Goods Receipts, and Vendor Invoices using a custom Z-table, and displays results via an interactive ALV report.

> Due to system constraints, a simulated dataset was created to represent SAP tables like EKKO/EKPO (PO), MSEG (GR), and RBKP/RSEG (Invoice). This approach mimics real-world MM-FI integration and is completely valid in academic SAP environments.

---

## 🔧 Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | ABAP (Advanced Business Application Programming) |
| Platform | SAP NetWeaver / SAP S/4HANA (simulated) |
| UI | CL_SALV_TABLE (ALV Grid) |
| Table | Custom Z-Table (ZINV_VALIDATION) |
| Tools | SE11, SE38, SE16, SM30 |

---

## 📁 Project Structure

```
SmartInvoiceValidation/
│
├── abap/
│   ├── ZINV_VALIDATION_table.abap       → Table definition (SE11)
│   ├── ZSMART_INVOICE_VALIDATION.abap   → Main validation program (SE38)
│   └── ZLOAD_INV_TEST_DATA.abap         → Test data loader
│
├── docs/
│   └── ProjectReport.pdf                → Full project documentation
│
├── data/
│   └── test_scenarios.md                → Test case descriptions
│
└── README.md
```

---

## ⚙️ Features

### ✅ Selection Screen
- Filter by Invoice ID range
- Filter by Vendor ID
- Filter by PO Number
- Filter output by status (ALL / VALID / WARNING / BLOCKED)

### 🔍 Core 3-Way Matching Logic

```abap
IF gr_qty = 0 → BLOCKED   (No Goods Receipt)
ELSEIF inv_qty > gr_qty → BLOCKED   (Qty exceeds GR)
ELSEIF inv_price ≠ po_price → WARNING  (Price mismatch)
ELSE → VALID  (OK for FI posting)
```

### 📊 ALV Output Columns
- Invoice ID | Vendor ID | Purchase Order
- PO Qty | GR Qty | Invoice Qty | **Qty Difference**
- PO Price | Invoice Price | **Price Difference**
- **Status** | **Validation Message**

### 🚦 Status Indicators
| Status | Meaning | Color |
|--------|---------|-------|
| VALID | 3-way match successful | 🟢 Green |
| WARNING | Price mismatch, needs review | 🟡 Yellow |
| BLOCKED | Cannot post to FI | 🔴 Red |

### 📥 Excel Download
Built-in via CL_SALV_TABLE functions toolbar

---

## 🧪 Test Scenarios

| Invoice | PO Qty | GR Qty | Inv Qty | PO Price | Inv Price | Expected |
|---------|--------|--------|---------|----------|-----------|----------|
| INV001 | 100 | 100 | 100 | 500 | 500 | ✅ VALID |
| INV002 | 50 | 30 | 50 | 45000 | 45000 | 🔴 BLOCKED |
| INV003 | 200 | 200 | 200 | 150 | 175 | 🟡 WARNING |
| INV004 | 5 | 0 | 5 | 200000 | 200000 | 🔴 BLOCKED |
| INV005 | 20 | 15 | 15 | 8000 | 8000 | ✅ VALID |

---

## 🚀 Implementation Steps

### Step 1 — Create Table (SE11)
1. Open SE11 → Select "Database Table" → Enter `ZINV_VALIDATION`
2. Add fields as defined in `ZINV_VALIDATION_table.abap`
3. Activate the table

### Step 2 — Load Test Data (SE38)
1. Create program `ZLOAD_INV_TEST_DATA` in SE38
2. Copy code from `ZLOAD_INV_TEST_DATA.abap`
3. Execute (F8) to insert test records

### Step 3 — Create Main Program (SE38)
1. Create program `ZSMART_INVOICE_VALIDATION`
2. Copy code from `ZSMART_INVOICE_VALIDATION.abap`
3. Activate and Execute

### Step 4 — Test All Scenarios
1. Run with default selection (all invoices)
2. Filter by STATUS = 'BLOCKED' to view blocked invoices
3. Use Excel download from ALV toolbar

---

## 💡 Why This Project Stands Out

- ✅ Implements real-world **3-way matching** logic used in SAP MM-FI
- ✅ Uses **CL_SALV_TABLE** — modern, object-oriented ALV approach
- ✅ Custom **validation layer** before FI posting (mimics real workflow)
- ✅ Covers **4 distinct business scenarios** with computed differences
- ✅ Built-in **Excel export** capability
- ✅ Clean modular structure: FETCH → VALIDATE → DISPLAY

---

## 🔮 Future Improvements

- Integration with real SAP tables (EKKO, EKPO, MSEG, RBKP, RSEG)
- Email notification to AP team on BLOCKED invoices
- Workflow integration for WARNING status review
- Dashboard using SAP Fiori / SAPUI5
- Tolerance-based matching (e.g., ±2% price variance allowed)

---

*Project submitted as part of SAP ABAP training — Academic use only.*
