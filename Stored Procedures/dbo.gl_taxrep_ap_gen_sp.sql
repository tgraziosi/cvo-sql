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
                               CREATE PROCEDURE [dbo].[gl_taxrep_ap_gen_sp] @start_date int, 
@end_date int, @report_cur smallint, @ret_val int OUTPUT AS BEGIN  IF ((@start_date IS NULL) OR (@end_date IS NULL) OR 
 (@report_cur IS NULL)) RETURN 2 SELECT @ret_val = 0 SET ROWCOUNT 0  INSERT #gl_taxrep 
(
 trx_ctrl_num,  doc_ctrl_num,  trx_type,  tax_box_code,  tax_box_rep_seq,  tax_type_code, 
 tax_type_desc,  description,  nat_cur_code,  amt_net,  amt_tax,  rate_home,  rate_oper, 
 date_applied,  date_doc,  tax_type 
)
SELECT  apvohdr.trx_ctrl_num,  apvohdr.doc_ctrl_num,  aptrxtax.trx_type,  gltaxboxdet.tax_box_code, 
 gltaxboxdet.sequence_id,  aptrxtax.tax_type_code,  '',  '',  apvohdr.currency_code, 
  aptrxtax.amt_taxable,  SIGN(aptrxtax.amt_tax)*aptrxtax.amt_tax,  apvohdr.rate_home, 
 apvohdr.rate_oper,  apvohdr.date_applied,  apvohdr.date_doc,  CASE SIGN(aptrxtax.amt_tax) 
 WHEN -1 THEN 0  ELSE 1  END FROM  apvohdr,  aptrxtax,  gltaxboxdet,  aptxtype WHERE 
 aptrxtax.tax_type_code = gltaxboxdet.tax_type_code AND  aptrxtax.tax_type_code = aptxtype.tax_type_code AND 
 aptrxtax.trx_type = 4091 AND  aptrxtax.trx_ctrl_num = apvohdr.trx_ctrl_num AND  apvohdr.date_applied BETWEEN @start_date AND @end_date 
IF (@@error <>0)  BEGIN  SELECT @ret_val = 1  ROLLBACK TRAN  RETURN @ret_val  END 
 INSERT #gl_taxrep 
(
 trx_ctrl_num,  doc_ctrl_num,  trx_type,  tax_box_code,  tax_box_rep_seq,  tax_type_code, 
 tax_type_desc,  description,  nat_cur_code,  amt_net,  amt_tax,  rate_home,  rate_oper, 
 date_applied,  date_doc,  tax_type 
)
SELECT  apdmhdr.trx_ctrl_num,  apdmhdr.doc_ctrl_num,  aptrxtax.trx_type,  gltaxboxdet.tax_box_code, 
 gltaxboxdet.sequence_id,  aptrxtax.tax_type_code,  '',  '',  apdmhdr.currency_code, 
  (-1)*aptrxtax.amt_taxable,  (-1)*aptrxtax.amt_tax,  apdmhdr.rate_home,  apdmhdr.rate_oper, 
 apdmhdr.date_applied,  apdmhdr.date_doc,  CASE SIGN(aptrxtax.amt_tax)  WHEN -1 THEN 0 
 ELSE 1  END FROM  apdmhdr,  aptrxtax,  gltaxboxdet,  aptxtype WHERE  aptrxtax.tax_type_code = gltaxboxdet.tax_type_code AND 
 aptrxtax.tax_type_code = aptxtype.tax_type_code AND  aptrxtax.trx_type = 4092 AND 
 aptrxtax.trx_ctrl_num = apdmhdr.trx_ctrl_num AND  apdmhdr.date_applied BETWEEN @start_date AND @end_date 
IF (@@error <>0)  BEGIN  SELECT @ret_val = 1  ROLLBACK TRAN  RETURN @ret_val  END 
 INSERT #gl_taxrep 
(
 trx_ctrl_num,  doc_ctrl_num,  trx_type,  tax_box_code,  tax_box_rep_seq,  tax_type_code, 
 tax_type_desc,  description,  nat_cur_code,  amt_net,  amt_tax,  rate_home,  rate_oper, 
 date_applied,  date_doc,  tax_type 
)
SELECT  appyhdr.trx_ctrl_num,  appyhdr.doc_ctrl_num,  aptrxtax.trx_type,  gltaxboxdet.tax_box_code, 
 gltaxboxdet.sequence_id,  aptrxtax.tax_type_code,  '',  '',  appyhdr.currency_code, 
 (-1)*appyhdr.amt_net,  (-1)*aptrxtax.amt_tax,  appyhdr.rate_home,  appyhdr.rate_oper, 
 appyhdr.date_applied,  appyhdr.date_doc,  CASE SIGN(aptrxtax.amt_tax)  WHEN -1 THEN 0 
 ELSE 1  END FROM  appyhdr,  aptrxtax,  gltaxboxdet WHERE  aptrxtax.tax_type_code = gltaxboxdet.tax_type_code AND 
 aptrxtax.trx_type = 4111 AND  aptrxtax.trx_ctrl_num = appyhdr.trx_ctrl_num AND  appyhdr.date_applied BETWEEN @start_date AND @end_date 
IF (@@error <>0)  BEGIN  SELECT @ret_val = 1  ROLLBACK TRAN  RETURN @ret_val  END 
DELETE #gl_taxrep WHERE  EXISTS  (SELECT * FROM gl_taxrep_dtl td  WHERE td.trx_ctrl_num = #gl_taxrep.trx_ctrl_num 
 AND td.trx_type = #gl_taxrep.trx_type) OR  EXISTS  (SELECT * FROM gl_taxrep_dtl_hst tdh 
 WHERE tdh.trx_ctrl_num = #gl_taxrep.trx_ctrl_num  AND tdh.trx_type = #gl_taxrep.trx_type) OR 
 EXISTS  (SELECT * FROM gl_taxrep_open_dtl od  WHERE od.trx_ctrl_num = #gl_taxrep.trx_ctrl_num 
 AND od.trx_type = #gl_taxrep.trx_type) OR  EXISTS  (SELECT * FROM gl_taxrep_open_dtl_hst odh 
 WHERE odh.trx_ctrl_num = #gl_taxrep.trx_ctrl_num  AND odh.trx_type = #gl_taxrep.trx_type) 
IF (@@error <>0)  BEGIN  SELECT @ret_val = 1  ROLLBACK TRAN  RETURN @ret_val  END 
UPDATE  tr SET  tr.description = ISNULL( tb.description, '' ) FROM  #gl_taxrep tr JOIN gltaxbox tb 
 ON tr.tax_box_code = tb.tax_box_code UPDATE  tr SET  tr.tax_type_desc = ISNULL( tt.tax_type_desc, '' ) 
FROM  #gl_taxrep tr JOIN aptxtype tt  ON tr.tax_type_code = tt.tax_type_code END 
GO
GRANT EXECUTE ON  [dbo].[gl_taxrep_ap_gen_sp] TO [public]
GO
