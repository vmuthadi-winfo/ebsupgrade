       
         
-- Purchasing
SELECT 'Transaction'     category
      ,'Purchasing'      module
      ,'Purchase Orders' object_type 
      ,(SELECT COUNT(1) 
          FROM po_headers_all)         total_volume
      ,(SELECT COUNT(1) 
          FROM po_headers_all
         WHERE closed_code ='OPEN')     open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM po_headers_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 UNION ALL
SELECT 'Transaction'          category
      ,'Purchasing'           module
      ,'Purchase Order Lines' object_type 
      ,(SELECT COUNT(1) 
          FROM po_lines_all)         total_volume
      ,(SELECT COUNT(1) 
          FROM po_headers_all poh
              ,po_lines_all   pol
         WHERE poh.closed_code  = 'OPEN'
           AND poh.po_header_id = pol.po_header_id)     open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM po_lines_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 UNION ALL
SELECT 'Transaction'     category
      ,'Purchasing'      module
      ,'Requisitions'   object_type 
      ,(SELECT COUNT(1) 
          FROM po_requisition_headers_all)         total_volume
      ,NULL                                        open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM po_requisition_headers_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 UNION ALL
SELECT 'Transaction'          category
      ,'Purchasing'           module
      ,'Requisition Lines' object_type 
      ,(SELECT COUNT(1) 
          FROM po_requisition_lines_all)         total_volume
      ,NULL                                      open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM po_requisition_lines_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
  UNION ALL
SELECT 'Master Data'     category
      ,'Purchasing'      module
      ,'Suppliers'       object_type 
      ,(SELECT COUNT(1) 
          FROM ap_suppliers)         total_volume
      ,NULL                          open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM ap_suppliers 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 UNION ALL
SELECT 'Transaction'          category
      ,'Purchasing'           module
      ,'Supplier Sites'       object_type 
      ,(SELECT COUNT(1) 
          FROM ap_supplier_sites_all)         total_volume
      ,NULL                                      open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM ap_supplier_sites_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual

-- Payables 
 
SELECT 'Transaction'             category
      ,'Payables'                module
      ,'Invoices'                object_type 
      ,(SELECT COUNT(1) 
          FROM ap_invoices_all)  total_volume
      ,''                        open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM ap_invoices_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 UNION ALL 
SELECT 'Transaction'     category
      ,'Payables'        module
      ,'Invoice Lines'   object_type 
      ,(SELECT COUNT(1) 
          FROM ap_invoice_lines_all)   total_volume
      ,''                              open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM ap_invoice_lines_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 UNION ALL
 SELECT 'Transaction'             category
      ,'Payables'                module
      ,'Expense Reports'                object_type 
      ,(SELECT COUNT(1) 
          FROM ap_expense_report_headers_all)  total_volume
      ,''                        open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM ap_expense_report_headers_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 UNION ALL 
SELECT 'Transaction'     category
      ,'Payables'        module
      ,'Expense Report Lines'   object_type 
      ,(SELECT COUNT(1) 
          FROM ap_expense_report_lines_all)   total_volume
      ,''                              open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM ap_expense_report_lines_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
  UNION ALL 
SELECT 'Transaction'     category
      ,'Payables'        module
      ,'Payments'   object_type 
      ,(SELECT COUNT(1) 
          FROM ap_checks_all)   total_volume
      ,''                              open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM ap_checks_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 
 --Projects
 
SELECT 'Transaction'             category
      ,'Projects'                module
      ,'Projects'                object_type 
      ,(SELECT COUNT(1) 
          FROM pa_projects_all
         WHERE template_flag='N'
          )  total_volume
      ,(SELECT COUNT(1) 
          FROM pa_projects_all     pap
              ,pa_project_statuses ps
         WHERE pap.template_flag      ='N'
           AND pap.project_status_code = ps.project_status_code
           AND ps.project_status_name <> 'Completed')  open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM pa_projects_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 UNION ALL 
SELECT 'Transaction'             category
      ,'Projects'                module
      ,'Project Tasks'           object_type 
      ,(SELECT COUNT(1) 
          FROM pa_projects_all pap
              ,pa_tasks        pat
         WHERE pap.template_flag='N'
           AND pap.project_id = pat.project_id
          )  total_volume
      ,(SELECT COUNT(1) 
          FROM pa_projects_all     pap
              ,pa_project_statuses ps
              ,pa_tasks        pat
         WHERE pap.template_flag      ='N'
           AND pap.project_status_code = ps.project_status_code
           AND ps.project_status_name <> 'Completed'
           AND pap.project_id = pat.project_id)  open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM pa_tasks 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
  UNION ALL 
SELECT 'Transaction'             category
      ,'Projects'                module
      ,'Expenditure Items'           object_type 
      ,(SELECT COUNT(1) 
          FROM pa_projects_all pap
              ,pa_expenditure_items_all        pae
         WHERE pap.template_flag='N'
           AND pap.project_id = pae.project_id
          )  total_volume
      ,(SELECT COUNT(1) 
          FROM pa_projects_all     pap
              ,pa_project_statuses ps
              ,pa_expenditure_items_all        pae
         WHERE pap.template_flag      ='N'
           AND pap.project_status_code = ps.project_status_code
           AND ps.project_status_name <> 'Completed'
           AND pap.project_id = pae.project_id)  open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM pa_expenditure_items_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 UNION ALL
 SELECT 'Transaction'             category
      ,'Projects'                module
      ,'Agreements'                object_type 
      ,(SELECT COUNT(1) 
          FROM pa_agreements_all
          )  total_volume
      ,NULL  open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM pa_agreements_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 
 -- Receivables
 
 SELECT 'Transaction'             category
      ,'Receivables'                module
      ,'Invoices'                object_type 
      ,(SELECT COUNT(1) 
          FROM ra_customer_trx_all)  total_volume
      ,''                        open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM ra_customer_trx_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 UNION ALL 
SELECT 'Transaction'     category
      ,'Receivables'        module
      ,'Invoice Lines'   object_type 
      ,(SELECT COUNT(1) 
          FROM ra_customer_trx_lines_all)   total_volume
      ,''                              open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM ra_customer_trx_lines_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
  UNION ALL 
SELECT 'Transaction'     category
      ,'Receivables'        module
      ,'Cash Receipts'   object_type 
      ,(SELECT COUNT(1) 
          FROM ar_cash_receipts_all)   total_volume
      ,''                              open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM ar_cash_receipts_all 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
   UNION ALL 
SELECT 'Master Data'     category
      ,'Receivables'        module
      ,'Customers'   object_type 
      ,(SELECT COUNT(1) 
          FROM hz_cust_accounts)   total_volume
      ,''                              open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM hz_cust_accounts 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 
 --HR
 
 SELECT 'Master Data'     category
      ,'Human Resources'        module
      ,'Employees'   object_type 
      ,(SELECT COUNT(1) 
          FROM per_all_people_f)   total_volume
      ,(SELECT COUNT(1) 
          FROM per_people_x)                             open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM per_all_people_f 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
 
 
-- GLB

 SELECT 'Master Data'     category
      ,'General Ledger'        module
      ,'Ledgers'   object_type 
      ,(SELECT COUNT(1) 
          FROM gl_ledgers)   total_volume
      ,NULL                           open_volume
      ,NULL monthly_volume
 FROM dual
 UNION ALL
SELECT 'Transaction'     category
      ,'General Ledger'        module
      ,'Employees'   object_type 
      ,(SELECT COUNT(1) 
          FROM gl_je_lines)   total_volume
      ,NULL                             open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(creation_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM gl_je_lines 
                 WHERE creation_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(creation_date,'MON-YY'))) monthly_volume
 FROM dual
  UNION ALL
SELECT 'Transaction'     category
      ,'General Ledger'        module
      ,'GL Accounts'   object_type 
      ,(SELECT COUNT(1) 
          FROM gl_code_combinations)   total_volume
      ,NULL                             open_volume
      ,(SELECT ROUND(AVG(monthly_volume))
          FROM (SELECT TO_CHAR(last_update_date,'MON-YY')
                      ,COUNT(1)         monthly_volume
                  FROM gl_code_combinations 
                 WHERE last_update_date > ADD_MONTHS(TRUNC(SYSDATE,'MM'),-12)
              GROUP BY TO_CHAR(last_update_date,'MON-YY'))) monthly_volume
 FROM dual
 