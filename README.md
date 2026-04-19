# 🧾 Smart Invoice Validation System

> An automated **3-way invoice matching system** built in SAP ABAP that validates vendor invoices against Purchase Orders and Goods Receipts — preventing overpayments, price inflation, and payments without delivery confirmation.

![ABAP](https://img.shields.io/badge/Language-ABAP-0077CC?style=flat-square&logo=sap&logoColor=white)
![SAP](https://img.shields.io/badge/Platform-SAP%20S%2F4HANA-1A9C3E?style=flat-square&logo=sap&logoColor=white)
![ALV](https://img.shields.io/badge/UI-CL__SALV__TABLE-6C3FC4?style=flat-square)
![Status](https://img.shields.io/badge/Status-Complete-2ea043?style=flat-square)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Problem Statement](#-problem-statement)
- [How It Works](#-how-it-works)
- [Tech Stack](#-tech-stack)
- [Database Table](#-database-table--zinv_validation)
- [Program Structure](#-program-structure)
- [Test Cases](#-test-cases)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Future Improvements](#-future-improvements)

---

## 🌐 Overview

This project simulates the **SAP Procure-to-Pay (P2P)** cycle using a custom Z-table and an ABAP executable program. It replicates the core invoice validation logic used in real SAP MM-FI environments — without requiring access to production SAP tables.

| SAP Table (Real) | Simulated By | Data Represented |
|------------------|--------------|-----------------|
| `EKKO` / `EKPO` | `ZINV_VALIDATION` | Purchase Order Header & Items |
| `MSEG` | `ZINV_VALIDATION` | Goods Receipt Quantities |
| `RBKP` / `RSEG` | `ZINV_VALIDATION` | Invoice Header & Line Items |

---

## ❗ Problem Statement

Manual invoice processing in enterprise procurement leads to three critical failure modes:

| Issue | Business Impact |
|-------|----------------|
| Invoice quantity exceeds goods received | Overpayment to vendors |
| Invoice price higher than agreed PO price | Undetected cost inflation |
| Invoice raised before Goods Receipt is posted | Payment without delivery confirmation |

This system automates all three checks through a rule-based validation engine before any FI posting occurs.

---

## ⚙️ How It Works

### Validation Logic — 3-Way Matching

```abap
IF gr_qty = 0                        "No Goods Receipt posted
  → STATUS = 'BLOCKED'

ELSEIF inv_qty > gr_qty              "Invoice overbills received qty
  → STATUS = 'BLOCKED'

ELSEIF inv_price <> po_price         "Price differs from PO agreement
  → STATUS = 'WARNING'

ELSE                                 "All checks passed
  → STATUS = 'VALID'
ENDIF
```

### Program Flow

```
User runs ZSMART_INVOICE_VALIDATION (SE38)
           │
           ▼
    Selection Screen
    (Invoice ID / Vendor / PO / Status filter)
           │
           ▼
     FORM fetch_data
    SELECT from ZINV_VALIDATION
           │
           ▼
    FORM validate_data
    ├── Compute QTY_DIFF  = INV_QTY  − GR_QTY
    ├── Compute PRICE_DIFF = INV_PRICE − PO_PRICE
    └── Assign STATUS: BLOCKED / WARNING / VALID
           │
           ▼
     FORM display_alv
    CL_SALV_TABLE → ALV Grid Output
    (Sort / Filter / Excel Export)
```

---

## 🔧 Tech Stack

| Component | Detail |
|-----------|--------|
| **Language** | ABAP (Advanced Business Application Programming) |
| **Platform** | SAP NetWeaver / SAP S/4HANA |
| **UI Framework** | `CL_SALV_TABLE` — Object-Oriented ALV Grid |
| **Database Table** | `ZINV_VALIDATION` — Custom Transparent Z-Table |
| **Development Transactions** | SE11, SE38, SE16, SA38, SM30 |
| **Export** | Excel (`.xlsx`) via ALV built-in toolbar |
| **Compatibility** | SAP ECC 6.0 / S/4HANA |

---

## 🗄️ Database Table — `ZINV_VALIDATION`

> Create in transaction **SE11** as a Transparent Table.

| Field | Type | Length | Key | Description |
|-------|------|--------|-----|-------------|
| `INV_ID` | CHAR | 20 | ✅ | Invoice Number — Primary Key |
| `VENDOR_ID` | CHAR | 20 | | Vendor Identifier |
| `PO_ID` | CHAR | 20 | | Purchase Order Number |
| `MATERIAL` | CHAR | 40 | | Material Description |
| `PO_QTY` | QUAN | 13 | | Purchase Order Quantity |
| `GR_QTY` | QUAN | 13 | | Goods Receipt Quantity |
| `INV_QTY` | QUAN | 13 | | Invoice Quantity |
| `PO_PRICE` | CURR | 15 | | PO Unit Price |
| `INV_PRICE` | CURR | 15 | | Invoice Unit Price |
| `QTY_DIFF` | QUAN | 13 | | Computed: `INV_QTY − GR_QTY` |
| `PRICE_DIFF` | CURR | 15 | | Computed: `INV_PRICE − PO_PRICE` |
| `STATUS` | CHAR | 10 | | `VALID` / `WARNING` / `BLOCKED` |
| `MESSAGE` | CHAR | 100 | | Validation message text |
| `CURRENCY` | CUKY | 5 | | Currency Key (e.g. INR) |
| `CREATED_ON` | DATS | 8 | | Record creation date |

**Technical Settings:** Data Class `APPL0` · Size Category `0` · Buffering: Not Allowed

---

## 🧩 Program Structure

The main program `ZSMART_INVOICE_VALIDATION` is split into three modular FORMs:

```
ZSMART_INVOICE_VALIDATION
│
├── FORM fetch_data
│     SELECT from ZINV_VALIDATION using selection screen filters
│     Handles no-data scenario with warning message
│
├── FORM validate_data
│     Computes QTY_DIFF and PRICE_DIFF per record
│     Applies 3-way matching logic → assigns STATUS + MESSAGE
│     Filters results by p_status (ALL / VALID / WARNING / BLOCKED)
│
└── FORM display_alv
      Initialises CL_SALV_TABLE
      Sets striped pattern, report header, all toolbar functions
      Configures column labels and layout save/restore
      Calls lo_alv->display()
```

---

## 🧪 Test Cases

Five scenarios covering every branch of the validation logic:

| Invoice | PO Qty | GR Qty | Inv Qty | PO Price | Inv Price | Expected | Reason |
|---------|--------|--------|---------|----------|-----------|----------|--------|
| `INV001` | 100 | 100 | 100 | 500 | 500 | ✅ VALID | Perfect 3-way match |
| `INV002` | 50 | 30 | 50 | 45,000 | 45,000 | 🔴 BLOCKED | Inv qty (50) > GR qty (30) |
| `INV003` | 200 | 200 | 200 | 150 | 175 | 🟡 WARNING | Price mismatch — ₹25/unit excess |
| `INV004` | 5 | 0 | 5 | 2,00,000 | 2,00,000 | 🔴 BLOCKED | No Goods Receipt (GR = 0) |
| `INV005` | 20 | 15 | 15 | 8,000 | 8,000 | ✅ VALID | Partial delivery, correctly invoiced |

---

## 🚀 Getting Started

### Step 1 — Create the Database Table (SE11)

```
SE11 → Database Table → Enter: ZINV_VALIDATION → Create
Add all 15 fields as listed in the Database Table section above
Set CURR field references: PO_PRICE, INV_PRICE, PRICE_DIFF → ref field: CURRENCY
Set QUAN field references: PO_QTY, GR_QTY, INV_QTY, QTY_DIFF → ref field: MEINS
Technical Settings: Data Class = APPL0, Size Category = 0
Activate (Ctrl+F3)
```

### Step 2 — Create the Main Program (SE38)

```
SE38 → Create program: ZSMART_INVOICE_VALIDATION
Paste the ENTIRE file: ABAP_Code/ZSMART_INVOICE_VALIDATION.abap
Activate (Ctrl+F3)
```

### Step 3 — Load Test Data + Run (first run only)

On the selection screen you will see a checkbox at the bottom:

```
☑ Load test data into ZINV_VALIDATION (first run only)
```

| Run | Checkbox | What happens |
|-----|----------|-------------|
| First time | ☑ Ticked | Inserts all 5 records, then validates and shows ALV |
| Every run after | ☐ Unticked | Validates and shows ALV directly |

> Alternatively, insert records manually via **SE16** using `Sample_Data/Test_Data_SE16.txt`.

### Step 4 — Test the Scenarios

| Filter | Input | Expected Result |
|--------|-------|----------------|
| Default (all) | INV001–INV010 | All 5 records, mixed statuses |
| By status | `BLOCKED` | INV002, INV004 only |
| By status | `WARNING` | INV003 only |
| By status | `VALID` | INV001, INV005 only |
| By vendor | `VEND_001` | INV001, INV003 only |
| Invalid ID | `INV999` | Warning: No records found |

---

## 📁 Project Structure

```
SmartInvoiceValidation/
│
├── ABAP_Code/
│   └── ZSMART_INVOICE_VALIDATION.abap
│       ├── Section 1 — ZINV_VALIDATION table definition (SE11 reference)
│       ├── Section 2 — Test scenario descriptions (comments)
│       └── Section 3 — Main program: FETCH_DATA, VALIDATE_DATA,
│                        DISPLAY_ALV, LOAD_TEST_DATA (all in one)
│
├── Sample_Data/
│   └── Test_Data_SE16.txt            ← Manual SE16 insertion guide + all 5 records
│
├── Screenshots_Placeholder/
│   └── SCREENSHOTS_GUIDE.txt         ← Guide for 8 SAP screenshots to capture
│
├── docs/
│   └── SmartInvoiceValidation_Report.docx   ← Full project report
│
├── PROJECT_DOCUMENTATION_Content.txt ← Copy-paste ready report content
└── README.md
```

---

## 🔮 Future Improvements

- [ ] **Live SAP table integration** — replace Z-table simulation with real `EKKO`, `EKPO`, `MSEG`, `RBKP`, `RSEG` tables
- [ ] **Tolerance-based matching** — configurable price variance threshold (e.g. ±2%) to reduce false warnings
- [ ] **SAP Workflow integration** — route `WARNING` invoices to an AP manager approval step via WS-based workflow
- [ ] **Email notifications** — alert the Accounts Payable team on `BLOCKED` invoices via SAP Business Workplace (SBWP)
- [ ] **Fiori / SAPUI5 dashboard** — management-level KPI view showing total, blocked, and warning invoice counts
- [ ] **Audit log table** — record every validation run (timestamp, user, result) in a dedicated log Z-table for compliance

---

## 📄 License

This project is open for academic and learning purposes.
Feel free to use, adapt, or extend it for your own SAP ABAP training projects.
