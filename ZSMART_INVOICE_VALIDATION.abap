*&---------------------------------------------------------------------*
*& Program     : ZSMART_INVOICE_VALIDATION
*& Title       : Smart Invoice Validation System (Simulated SAP P2P)
*& Description : Validates invoices against PO and GR data using
*&               3-way matching logic (PO qty, GR qty, Invoice qty/price)
*& Author      : Harsh Raj
*& Roll Number : 2330162
*& Batch       : 2023-2027 | B.Tech-ECSc.
*& Course      : SAP ABAP Development Training
*& Created On  : 2024
*&---------------------------------------------------------------------*
*& References  : Simulates SAP tables:
*&               - EKKO/EKPO (Purchase Order Header & Item)
*&               - MSEG      (Goods Receipt)
*&               - RBKP/RSEG (Invoice Header & Item)
*&---------------------------------------------------------------------*


*&=====================================================================*
*& SECTION 1: DATABASE TABLE DEFINITION — ZINV_VALIDATION (SE11)
*&=====================================================================*
*& --- To be created in SE11 (ABAP Dictionary) ---
*& Table Name   : ZINV_VALIDATION
*& Short Text   : Smart Invoice Validation - Simulated SAP P2P Table
*& Delivery Cls : A (Application table - master and transaction data)
*& Data Browser : Display/Maintenance Allowed
*&
*& ---- FIELDS ----
*& Field Name   Key  Type   Len   Description
*& ----------   ---  ----   ---   -----------
*& MANDT         X   CLNT   3     Client
*& INV_ID        X   CHAR   20    Invoice Number (Primary Key)
*& VENDOR_ID         CHAR   20    Vendor Identifier
*& PO_ID             CHAR   20    Purchase Order Number
*& MATERIAL          CHAR   40    Material Description
*& PO_QTY            QUAN   13    Purchase Order Quantity
*& GR_QTY            QUAN   13    Goods Receipt Quantity
*& INV_QTY           QUAN   13    Invoice Quantity
*& PO_PRICE          CURR   15    PO Unit Price
*& INV_PRICE         CURR   15    Invoice Unit Price
*& QTY_DIFF          QUAN   13    Computed: INV_QTY - GR_QTY
*& PRICE_DIFF        CURR   15    Computed: INV_PRICE - PO_PRICE
*& STATUS            CHAR   10    VALID / WARNING / BLOCKED
*& MESSAGE           CHAR   100   Validation Message
*& CURRENCY          CUKY   5     Currency Key (INR)
*& CREATED_ON        DATS   8     Created Date
*&
*& ---- TECHNICAL SETTINGS ----
*& Data Class : APPL0 | Size Category : 0 | Buffering : Not Allowed
*&
*& ---- CURRENCY/QUANTITY REFERENCE FIELDS ----
*& PO_PRICE, INV_PRICE, PRICE_DIFF  -> Ref Field: CURRENCY
*& PO_QTY, GR_QTY, INV_QTY, QTY_DIFF -> Ref Field: MEINS
*&=====================================================================*


*&=====================================================================*
*& SECTION 2: TEST DATA — ZINV_VALIDATION (Load via SE38 / SM30)
*&=====================================================================*
*& Run this section as a standalone program ZLOAD_INV_TEST_DATA in SE38
*& to insert the 5 test records into the ZINV_VALIDATION table.
*&
*& SCENARIO 1: VALID — All quantities and prices match
*&   INV001 | VEND_001 | PO_2024_001 | Office Chairs
*&   PO_QTY=100, GR_QTY=100, INV_QTY=100 | PO_PRICE=500, INV_PRICE=500
*&   Expected: STATUS = VALID
*&
*& SCENARIO 2: BLOCKED — Invoice qty exceeds GR qty
*&   INV002 | VEND_002 | PO_2024_002 | Laptop Computers
*&   PO_QTY=50, GR_QTY=30, INV_QTY=50 | PO_PRICE=45000, INV_PRICE=45000
*&   Expected: STATUS = BLOCKED (Invoice qty 50 > GR qty 30)
*&
*& SCENARIO 3: WARNING — Price mismatch between Invoice and PO
*&   INV003 | VEND_001 | PO_2024_003 | Printer Cartridges
*&   PO_QTY=200, GR_QTY=200, INV_QTY=200 | PO_PRICE=150, INV_PRICE=175
*&   Expected: STATUS = WARNING (INV_PRICE 175 != PO_PRICE 150)
*&
*& SCENARIO 4: BLOCKED — No Goods Receipt (GR_QTY = 0)
*&   INV004 | VEND_003 | PO_2024_004 | Server Hardware
*&   PO_QTY=5, GR_QTY=0, INV_QTY=5 | PO_PRICE=200000, INV_PRICE=200000
*&   Expected: STATUS = BLOCKED (No GR found)
*&
*& SCENARIO 5: VALID — Partial delivery, invoice matches GR
*&   INV005 | VEND_002 | PO_2024_005 | Network Switches
*&   PO_QTY=20, GR_QTY=15, INV_QTY=15 | PO_PRICE=8000, INV_PRICE=8000
*&   Expected: STATUS = VALID (Partial delivery correctly invoiced)
*&---------------------------------------------------------------------*

REPORT zload_inv_test_data.

DATA: lt_data TYPE TABLE OF zinv_validation,
      ls_data TYPE zinv_validation.

" Record 1 - VALID
ls_data-mandt      = sy-mandt.
ls_data-inv_id     = 'INV001'.
ls_data-vendor_id  = 'VEND_001'.
ls_data-po_id      = 'PO_2024_001'.
ls_data-material   = 'Office Chairs'.
ls_data-po_qty     = 100.
ls_data-gr_qty     = 100.
ls_data-inv_qty    = 100.
ls_data-po_price   = 500.
ls_data-inv_price  = 500.
ls_data-status     = 'PENDING'.
ls_data-message    = 'Awaiting validation'.
ls_data-created_on = sy-datum.
APPEND ls_data TO lt_data. CLEAR ls_data.

" Record 2 - BLOCKED (qty exceeds GR)
ls_data-mandt      = sy-mandt.
ls_data-inv_id     = 'INV002'.
ls_data-vendor_id  = 'VEND_002'.
ls_data-po_id      = 'PO_2024_002'.
ls_data-material   = 'Laptop Computers'.
ls_data-po_qty     = 50.
ls_data-gr_qty     = 30.
ls_data-inv_qty    = 50.
ls_data-po_price   = 45000.
ls_data-inv_price  = 45000.
ls_data-status     = 'PENDING'.
ls_data-message    = 'Awaiting validation'.
ls_data-created_on = sy-datum.
APPEND ls_data TO lt_data. CLEAR ls_data.

" Record 3 - WARNING (price mismatch)
ls_data-mandt      = sy-mandt.
ls_data-inv_id     = 'INV003'.
ls_data-vendor_id  = 'VEND_001'.
ls_data-po_id      = 'PO_2024_003'.
ls_data-material   = 'Printer Cartridges'.
ls_data-po_qty     = 200.
ls_data-gr_qty     = 200.
ls_data-inv_qty    = 200.
ls_data-po_price   = 150.
ls_data-inv_price  = 175.
ls_data-status     = 'PENDING'.
ls_data-message    = 'Awaiting validation'.
ls_data-created_on = sy-datum.
APPEND ls_data TO lt_data. CLEAR ls_data.

" Record 4 - BLOCKED (no GR)
ls_data-mandt      = sy-mandt.
ls_data-inv_id     = 'INV004'.
ls_data-vendor_id  = 'VEND_003'.
ls_data-po_id      = 'PO_2024_004'.
ls_data-material   = 'Server Hardware'.
ls_data-po_qty     = 5.
ls_data-gr_qty     = 0.
ls_data-inv_qty    = 5.
ls_data-po_price   = 200000.
ls_data-inv_price  = 200000.
ls_data-status     = 'PENDING'.
ls_data-message    = 'Awaiting validation'.
ls_data-created_on = sy-datum.
APPEND ls_data TO lt_data. CLEAR ls_data.

" Record 5 - VALID (partial delivery)
ls_data-mandt      = sy-mandt.
ls_data-inv_id     = 'INV005'.
ls_data-vendor_id  = 'VEND_002'.
ls_data-po_id      = 'PO_2024_005'.
ls_data-material   = 'Network Switches'.
ls_data-po_qty     = 20.
ls_data-gr_qty     = 15.
ls_data-inv_qty    = 15.
ls_data-po_price   = 8000.
ls_data-inv_price  = 8000.
ls_data-status     = 'PENDING'.
ls_data-message    = 'Awaiting validation'.
ls_data-created_on = sy-datum.
APPEND ls_data TO lt_data. CLEAR ls_data.

" Insert all records
INSERT zinv_validation FROM TABLE lt_data.

IF sy-subrc = 0.
  COMMIT WORK.
  WRITE: / 'Test data loaded successfully. Records:', sy-dbcnt.
ELSE.
  ROLLBACK WORK.
  WRITE: / 'Error loading test data. Check if records already exist.'.
ENDIF.


*&=====================================================================*
*& SECTION 3: MAIN VALIDATION PROGRAM — ZSMART_INVOICE_VALIDATION (SE38)
*&=====================================================================*

REPORT zsmart_invoice_validation.

*----------------------------------------------------------------------*
*  TYPE DECLARATIONS
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_inv_data,
         inv_id     TYPE char20,
         vendor_id  TYPE char20,
         po_id      TYPE char20,
         material   TYPE char40,
         po_qty     TYPE p DECIMALS 2,
         gr_qty     TYPE p DECIMALS 2,
         inv_qty    TYPE p DECIMALS 2,
         po_price   TYPE p DECIMALS 2,
         inv_price  TYPE p DECIMALS 2,
         qty_diff   TYPE p DECIMALS 2,
         price_diff TYPE p DECIMALS 2,
         status     TYPE char10,
         message    TYPE char100,
       END OF ty_inv_data.

*----------------------------------------------------------------------*
*  INTERNAL TABLES & WORK AREAS
*----------------------------------------------------------------------*
DATA: lt_inv_data  TYPE TABLE OF ty_inv_data,
      ls_inv_data  TYPE ty_inv_data,
      lt_validated TYPE TABLE OF ty_inv_data.

*----------------------------------------------------------------------*
*  ALV REFERENCES
*----------------------------------------------------------------------*
DATA: lo_salv       TYPE REF TO cl_salv_table,
      lo_columns    TYPE REF TO cl_salv_columns_table,
      lo_column     TYPE REF TO cl_salv_column_table,
      lo_display    TYPE REF TO cl_salv_display_settings,
      lo_functions  TYPE REF TO cl_salv_functions_list,
      lo_layout     TYPE REF TO cl_salv_layout,
      lo_layout_key TYPE salv_s_layout_key.

*----------------------------------------------------------------------*
*  SELECTION SCREEN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_invid  FOR ls_inv_data-inv_id
                            DEFAULT 'INV001' TO 'INV010',
                  s_vendor FOR ls_inv_data-vendor_id,
                  s_poid   FOR ls_inv_data-po_id.
  PARAMETERS:     p_status TYPE char10 DEFAULT 'ALL'.
SELECTION-SCREEN END OF BLOCK blk1.

*----------------------------------------------------------------------*
*  INITIALIZATION
*----------------------------------------------------------------------*
INITIALIZATION.
  TEXT-001 = 'Invoice Validation Selection'.

*----------------------------------------------------------------------*
*  START OF SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM fetch_data.
  PERFORM validate_data.
  PERFORM display_alv.

*----------------------------------------------------------------------*
*& Form FETCH_DATA
*& Fetches data from Z-table (simulates reading from EKKO/EKPO/MSEG/RBKP)
*----------------------------------------------------------------------*
FORM fetch_data.
  SELECT inv_id
         vendor_id
         po_id
         material
         po_qty
         gr_qty
         inv_qty
         po_price
         inv_price
         status
         message
    FROM zinv_validation
    INTO TABLE lt_inv_data
   WHERE inv_id    IN s_invid
     AND vendor_id IN s_vendor.

  IF sy-subrc <> 0.
    MESSAGE 'No invoice records found for given selection.' TYPE 'W'.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
*& Form VALIDATE_DATA
*& Core 3-Way Matching Logic:
*&   1. Check GR exists (gr_qty > 0)
*&   2. Check Invoice qty does not exceed GR qty
*&   3. Check Price matches PO price
*& Also computes QTY_DIFF and PRICE_DIFF for ALV display
*----------------------------------------------------------------------*
FORM validate_data.
  LOOP AT lt_inv_data INTO ls_inv_data.

    " --- Calculate Difference Fields ---
    ls_inv_data-qty_diff   = ls_inv_data-inv_qty - ls_inv_data-gr_qty.
    ls_inv_data-price_diff = ls_inv_data-inv_price - ls_inv_data-po_price.

    " --- Core 3-Way Matching Validation Logic ---
    IF ls_inv_data-gr_qty = 0.
      ls_inv_data-status  = 'BLOCKED'.
      ls_inv_data-message = 'No Goods Receipt found for this PO'.

    ELSEIF ls_inv_data-inv_qty > ls_inv_data-gr_qty.
      ls_inv_data-status  = 'BLOCKED'.
      ls_inv_data-message = 'Invoice qty exceeds GR qty - blocked for payment'.

    ELSEIF ls_inv_data-inv_price <> ls_inv_data-po_price.
      ls_inv_data-status  = 'WARNING'.
      ls_inv_data-message = 'Price mismatch between Invoice and PO - review required'.

    ELSE.
      ls_inv_data-status  = 'VALID'.
      ls_inv_data-message = 'Invoice validated - OK for FI posting'.
    ENDIF.

    " --- Filter by Status if specified ---
    IF p_status = 'ALL' OR p_status = ls_inv_data-status.
      APPEND ls_inv_data TO lt_validated.
    ENDIF.

    CLEAR ls_inv_data.
  ENDLOOP.

  IF lt_validated IS INITIAL.
    MESSAGE 'No records match the validation filter.' TYPE 'W'.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
*& Form DISPLAY_ALV
*& Displays validated results using CL_SALV_TABLE with column headers
*----------------------------------------------------------------------*
FORM display_alv.
  TRY.
      " --- Create ALV Instance ---
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_salv
        CHANGING
          t_table      = lt_validated
      ).

      " --- Enable All Standard Functions (incl. Excel Download) ---
      lo_functions = lo_salv->get_functions( ).
      lo_functions->set_all( abap_true ).

      " --- Display Settings ---
      lo_display = lo_salv->get_display_settings( ).
      lo_display->set_striped_pattern( abap_true ).
      lo_display->set_list_header( 'Smart Invoice Validation Report - Simulated SAP P2P' ).

      " --- Column Configuration ---
      lo_columns = lo_salv->get_columns( ).
      lo_columns->set_optimize( abap_true ).

      TRY.
          lo_column ?= lo_columns->get_column( 'INV_ID' ).
          lo_column->set_long_text( 'Invoice ID' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'VENDOR_ID' ).
          lo_column->set_long_text( 'Vendor ID' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'PO_ID' ).
          lo_column->set_long_text( 'Purchase Order' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'MATERIAL' ).
          lo_column->set_long_text( 'Material' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'PO_QTY' ).
          lo_column->set_long_text( 'PO Quantity' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'GR_QTY' ).
          lo_column->set_long_text( 'GR Quantity' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'INV_QTY' ).
          lo_column->set_long_text( 'Invoice Quantity' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'QTY_DIFF' ).
          lo_column->set_long_text( 'Qty Difference' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'PO_PRICE' ).
          lo_column->set_long_text( 'PO Unit Price' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'INV_PRICE' ).
          lo_column->set_long_text( 'Invoice Price' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'PRICE_DIFF' ).
          lo_column->set_long_text( 'Price Difference' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'STATUS' ).
          lo_column->set_long_text( 'Status' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      TRY.
          lo_column ?= lo_columns->get_column( 'MESSAGE' ).
          lo_column->set_long_text( 'Validation Message' ).
      CATCH cx_salv_not_found. "#EC NO_HANDLER
      ENDTRY.

      " --- Layout Key for Save/Restore ---
      lo_layout = lo_salv->get_layout( ).
      lo_layout_key-report = sy-repid.
      lo_layout->set_key( lo_layout_key ).
      lo_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).

      " --- Display ALV ---
      lo_salv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'E'.
  ENDTRY.
ENDFORM.

*----------------------------------------------------------------------*
*& COLOR CODING NOTE (for examiner):
*& STATUS column color highlighting can be achieved using:
*&   GREEN  (C_COLOR_1) = VALID
*&   YELLOW (C_COLOR_4) = WARNING
*&   RED    (C_COLOR_6) = BLOCKED
*----------------------------------------------------------------------*
