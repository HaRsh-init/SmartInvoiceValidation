# Smart Invoice Validation

ABAP mini-project for validating vendor invoices in a simulated SAP Procure-to-Pay (P2P) flow using 3-way matching logic (PO, GR, Invoice).

## Author

- **Name:** Harsh Raj
- **Roll Number:** 2330162
- **Program:** B.Tech (ECSc.)
- **Batch:** 2023–2027

## Project Overview

This project validates invoice data stored in custom table `ZINV_VALIDATION` and classifies each invoice as:

- `VALID`
- `WARNING`
- `BLOCKED`

Validation output is shown in ALV using `CL_SALV_TABLE`, with computed quantity and price differences.

## Core Validation Logic

1. If `GR_QTY = 0` → `BLOCKED`
2. Else if `INV_QTY > GR_QTY` → `BLOCKED`
3. Else if `INV_PRICE <> PO_PRICE` → `WARNING`
4. Else → `VALID`

## Repository Files

This repository currently contains:

- `/home/runner/work/SmartInvoiceValidation/SmartInvoiceValidation/ZSMART_INVOICE_VALIDATION.abap`  
  Contains:
  - table definition notes for `ZINV_VALIDATION`
  - test data loader program (`ZLOAD_INV_TEST_DATA`)
  - main report (`ZSMART_INVOICE_VALIDATION`)
- `/home/runner/work/SmartInvoiceValidation/SmartInvoiceValidation/Test_Data_SE16.txt`  
  Manual test-data reference for SE16/SE38
- `/home/runner/work/SmartInvoiceValidation/SmartInvoiceValidation/SmartInvoiceValidation_Report.pdf`  
  Project report/documentation
- `/home/runner/work/SmartInvoiceValidation/SmartInvoiceValidation/README.md`

## SAP Setup / Execution

### 1) Create Table in SE11

Create table `ZINV_VALIDATION` with the fields described in `ZSMART_INVOICE_VALIDATION.abap` (Section 1), then activate it.

### 2) Load Test Data

Use either:

- `ZLOAD_INV_TEST_DATA` (code in Section 2 of `ZSMART_INVOICE_VALIDATION.abap`)
- manual entries from `Test_Data_SE16.txt`

### 3) Run Main Program

Run report `ZSMART_INVOICE_VALIDATION` (Section 3 in the ABAP file).

Selection options:

- Invoice range (`S_INVID`)
- Vendor (`S_VENDOR`)
- PO (`S_POID`)
- Status (`P_STATUS`: `ALL` / `VALID` / `WARNING` / `BLOCKED`)

## Sample Scenarios

- `INV001` → VALID
- `INV002` → BLOCKED (invoice qty exceeds GR)
- `INV003` → WARNING (price mismatch)
- `INV004` → BLOCKED (no GR)
- `INV005` → VALID (partial delivery, correctly invoiced)

## Tools / Transactions Used

- `SE11` (table creation)
- `SE38` (program execution)
- `SE16` / `SM30` (data view/entry)

## Notes

- This is a simulated academic project (SAP MM-FI style workflow).
- Real SAP standard tables referenced conceptually: `EKKO`, `EKPO`, `MSEG`, `RBKP`, `RSEG`.
