SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
                       CREATE PROCEDURE [dbo].[gl_opentaxrep_ap_prn_sp] @report_date int, 
@report_cur smallint, @ret_val int OUTPUT AS BEGIN  IF ((@report_date IS NULL) OR (@report_cur IS NULL) ) RETURN 2 
SELECT @ret_val = 0 SET ROWCOUNT 0  INSERT #gl_opentaxrepprn 
(
 trx_ctrl_num,  doc_ctrl_num,  trx_type,  tax_box_code,  tax_box_rep_seq,  tax_type_code, 
 tax_type_desc,  description,  nat_cur_code,  amt_net,  amt_tax,  rate_home,  rate_oper, 
 date_applied,  date_doc,  tax_type 
)
SELECT  apvohdr.trx_ctrl_num,  apvohdr.doc_ctrl_num,  aptrxtax.trx_type,  gl_taxrep_open_dtl_hst.tax_box_code, 
 1,  aptrxtax.tax_type_code,  '',  '',  apvohdr.currency_code,   aptrxtax.amt_taxable, 
 SIGN(aptrxtax.amt_tax)*aptrxtax.amt_tax,  apvohdr.rate_home,  apvohdr.rate_oper, 
 apvohdr.date_applied,  apvohdr.date_doc,  CASE SIGN(aptrxtax.amt_tax)  WHEN -1 THEN 0 
 ELSE 1  END FROM  apvohdr,  aptrxtax,  gl_taxrep_open_dtl_hst,  aptxtype WHERE  gl_taxrep_open_dtl_hst.trx_ctrl_num = apvohdr.trx_ctrl_num AND 
 aptrxtax.tax_type_code = aptxtype.tax_type_code AND  gl_taxrep_open_dtl_hst.trx_type = 4091 AND 
 aptrxtax.trx_ctrl_num = apvohdr.trx_ctrl_num AND  gl_taxrep_open_dtl_hst.tax_type_code = aptrxtax.tax_type_code AND 
 gl_taxrep_open_dtl_hst.report_date = @report_date  INSERT #gl_opentaxrepprn 
(
 trx_ctrl_num,  doc_ctrl_num,  trx_type,  tax_box_code,  tax_box_rep_seq,  tax_type_code, 
 tax_type_desc,  description,  nat_cur_code,  amt_net,  amt_tax,  rate_home,  rate_oper, 
 date_applied,  date_doc,  tax_type 
)
SELECT  apdmhdr.trx_ctrl_num,  apdmhdr.doc_ctrl_num,  aptrxtax.trx_type,  gl_taxrep_open_dtl_hst.tax_box_code, 
 1,  aptrxtax.tax_type_code,  '',  '',  apdmhdr.currency_code,   (-1)*aptrxtax.amt_taxable, 
 (-1)*aptrxtax.amt_tax,  apdmhdr.rate_home,  apdmhdr.rate_oper,  apdmhdr.date_applied, 
 apdmhdr.date_doc,  CASE SIGN(aptrxtax.amt_tax)  WHEN -1 THEN 0  ELSE 1  END FROM 
 apdmhdr,  aptrxtax,  gl_taxrep_open_dtl_hst,  aptxtype WHERE  gl_taxrep_open_dtl_hst.trx_ctrl_num = apdmhdr.trx_ctrl_num AND 
 aptrxtax.tax_type_code = aptxtype.tax_type_code AND  gl_taxrep_open_dtl_hst.trx_type = 4092 AND 
 aptrxtax.trx_ctrl_num = apdmhdr.trx_ctrl_num AND  gl_taxrep_open_dtl_hst.tax_type_code = aptrxtax.tax_type_code AND 
 gl_taxrep_open_dtl_hst.report_date = @report_date  INSERT #gl_opentaxrepprn 
(
 trx_ctrl_num,  doc_ctrl_num,  trx_type,  tax_box_code,  tax_box_rep_seq,  tax_type_code, 
 tax_type_desc,  description,  nat_cur_code,  amt_net,  amt_tax,  rate_home,  rate_oper, 
 date_applied,  tax_type 
)
SELECT  appyhdr.trx_ctrl_num,  appyhdr.doc_ctrl_num,  aptrxtax.trx_type,  gl_taxrep_open_dtl_hst.tax_box_code, 
 1,  aptrxtax.tax_type_code,  '',  '',  appyhdr.currency_code,  (-1)*appyhdr.amt_net, 
 (-1)*aptrxtax.amt_tax,  appyhdr.rate_home,  appyhdr.rate_oper,  appyhdr.date_applied, 
 CASE SIGN(aptrxtax.amt_tax)  WHEN -1 THEN 0  ELSE 1  END FROM  appyhdr,  aptrxtax, 
 gltaxboxdet,  gl_taxrep_open_dtl_hst WHERE  gl_taxrep_open_dtl_hst.trx_ctrl_num = appyhdr.trx_ctrl_num AND 
 gl_taxrep_open_dtl_hst.trx_type = 4911 AND  aptrxtax.trx_ctrl_num = appyhdr.trx_ctrl_num AND 
 gl_taxrep_open_dtl_hst.tax_type_code = aptrxtax.tax_type_code AND  gl_taxrep_open_dtl_hst.report_date = @report_date 
UPDATE  tr SET  tr.description = ISNULL( tb.description, '' ) FROM  #gl_opentaxrepprn tr JOIN gltaxbox tb 
 ON tr.tax_box_code = tb.tax_box_code UPDATE  tr SET  tr.tax_type_desc = ISNULL( tt.tax_type_desc, '' ) 
FROM  #gl_opentaxrepprn tr JOIN aptxtype tt  ON tr.tax_type_code = tt.tax_type_code 
IF (@@error <>0)  BEGIN  SELECT @ret_val = 1  ROLLBACK TRAN  RETURN @ret_val  END 
END 
GO
GRANT EXECUTE ON  [dbo].[gl_opentaxrep_ap_prn_sp] TO [public]
GO
