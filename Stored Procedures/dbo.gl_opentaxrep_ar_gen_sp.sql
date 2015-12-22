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
                            CREATE PROCEDURE [dbo].[gl_opentaxrep_ar_gen_sp] @report_date int, 
@report_cur smallint, @ret_val int OUTPUT AS BEGIN DECLARE @today int SELECT @ret_val = 0 
 IF ((@report_date IS NULL) OR  (@report_cur IS NULL)) RETURN 2 SET ROWCOUNT 0 INSERT 
 #gl_opentaxrep 
(
 trx_ctrl_num,  doc_ctrl_num,  trx_type,  tax_box_code,  tax_box_rep_seq,  tax_type_code, 
 tax_type_desc,  description,  nat_cur_code,  amt_net,  amt_tax,  rate_home,  rate_oper, 
 date_applied,  date_doc,  tax_type 
)
SELECT  artrx.trx_ctrl_num,  artrx.doc_ctrl_num,  artrx.trx_type,  gltaxboxdet.tax_box_code, 
 gltaxboxdet.sequence_id,  artrxtax.tax_type_code,  '',  '',  artrx.nat_cur_code, 
 CASE artrx.trx_type  WHEN 2021 THEN artrxtax.amt_taxable  WHEN 2031 THEN artrxtax.amt_taxable 
 WHEN 2141 THEN artrxtax.amt_taxable  ELSE (-1)*artrxtax.amt_taxable  END,  CASE artrx.trx_type 
 WHEN 2021 THEN artrxtax.amt_tax  WHEN 2031 THEN artrxtax.amt_tax  WHEN 2141 THEN artrxtax.amt_tax 
 ELSE (-1)*artrxtax.amt_tax  END,  artrx.rate_home,  artrx.rate_oper,  artrx.date_applied, 
 artrx.date_doc,  0 FROM  artrx,  artrxtax,  gltaxboxdet,  artxtype WHERE  artrxtax.doc_ctrl_num = artrx.doc_ctrl_num AND 
 artrxtax.tax_type_code = artxtype.tax_type_code AND  artrxtax.trx_type = artrx.trx_type AND 
 artrxtax.tax_type_code = gltaxboxdet.tax_type_code AND  artrx.date_applied < @report_date 
IF (@@error <>0)  BEGIN  SELECT @ret_val = 1  ROLLBACK TRAN  RETURN @ret_val  END 
 DELETE  #gl_opentaxrep WHERE  EXISTS  (SELECT * FROM gl_taxrep_dtl td WHERE td.trx_ctrl_num = #gl_opentaxrep.trx_ctrl_num 
 AND td.trx_type = #gl_opentaxrep.trx_type) OR  EXISTS  (SELECT * FROM gl_taxrep_dtl_hst tdh WHERE tdh.trx_ctrl_num = #gl_opentaxrep.trx_ctrl_num 
 AND tdh.trx_type = #gl_opentaxrep.trx_type) OR  EXISTS  (SELECT * FROM gl_taxrep_open_dtl od WHERE od.trx_ctrl_num = #gl_opentaxrep.trx_ctrl_num 
 AND od.trx_type = #gl_opentaxrep.trx_type) OR  EXISTS  (SELECT * FROM gl_taxrep_open_dtl_hst odh WHERE odh.trx_ctrl_num = #gl_opentaxrep.trx_ctrl_num 
 AND odh.trx_type = #gl_opentaxrep.trx_type) IF (@@error <>0)  BEGIN  SELECT @ret_val = 1 
 ROLLBACK TRAN  RETURN @ret_val  END EXEC appdate_sp @today OUTPUT DELETE  #gl_opentaxrep 
WHERE  date_applied >= ISNULL((SELECT MAX(end_date) FROM gl_taxrep_hdr_hst), @today) 
UPDATE  tr SET  tr.description = ISNULL( tb.description, '' ) FROM  #gl_opentaxrep tr JOIN gltaxbox tb 
 ON tr.tax_box_code = tb.tax_box_code UPDATE  tr SET  tr.tax_type_desc = ISNULL( tt.tax_type_desc, '' ) 
FROM  #gl_opentaxrep tr JOIN artxtype tt  ON tr.tax_type_code = tt.tax_type_code 
IF (@@error <>0)  BEGIN  SELECT @ret_val = 1  ROLLBACK TRAN  RETURN @ret_val  END 
END 
GO
GRANT EXECUTE ON  [dbo].[gl_opentaxrep_ar_gen_sp] TO [public]
GO
