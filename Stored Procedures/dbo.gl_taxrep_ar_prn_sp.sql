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
                            CREATE PROCEDURE [dbo].[gl_taxrep_ar_prn_sp] @start_date int, 
@ret_val int OUTPUT AS BEGIN SELECT @ret_val = 0  IF ((@start_date IS NULL) ) RETURN 2 
SET ROWCOUNT 0 INSERT  #gl_taxrepprn 
(
 trx_ctrl_num,  doc_ctrl_num,  trx_type,  tax_box_code,  tax_box_rep_seq,  tax_type_code, 
 tax_type_desc,  description,  nat_cur_code,  amt_net,  amt_tax,  rate_home,  rate_oper, 
 date_applied,  date_doc,  tax_type 
)
SELECT  artrx.trx_ctrl_num,  artrx.doc_ctrl_num,  artrx.trx_type,  gl_taxrep_dtl_hst.tax_box_code, 
 1,  artrxtax.tax_type_code,  '',  '',  artrx.nat_cur_code,  CASE artrx.trx_type 
 WHEN 2021 THEN artrxtax.amt_taxable  WHEN 2031 THEN artrxtax.amt_taxable  WHEN 2141 THEN artrxtax.amt_taxable 
 ELSE (-1)*artrxtax.amt_taxable  END,  CASE artrx.trx_type  WHEN 2021 THEN artrxtax.amt_tax 
 WHEN 2031 THEN artrxtax.amt_tax  WHEN 2141 THEN artrxtax.amt_tax  ELSE (-1)*artrxtax.amt_tax 
 END,  artrx.rate_home,  artrx.rate_oper,  artrx.date_applied,  artrx.date_doc,  0 
FROM  artrx,  artrxtax,  gl_taxrep_dtl_hst,  artxtype WHERE  gl_taxrep_dtl_hst.trx_ctrl_num = artrx.trx_ctrl_num AND 
 artrxtax.tax_type_code = artxtype.tax_type_code AND  gl_taxrep_dtl_hst.trx_type = artrx.trx_type AND 
 artrxtax.doc_ctrl_num = artrx.doc_ctrl_num AND  gl_taxrep_dtl_hst.tax_type_code = artrxtax.tax_type_code AND 
 gl_taxrep_dtl_hst.start_date = @start_date IF (@@error <>0)  BEGIN  SELECT @ret_val = 1 
 ROLLBACK TRAN  RETURN @ret_val  END UPDATE  tr SET  tr.description = ISNULL( tb.description, '' ) 
FROM  #gl_taxrepprn tr JOIN gltaxbox tb  ON tr.tax_box_code = tb.tax_box_code UPDATE 
 tr SET  tr.tax_type_desc = ISNULL( tt.tax_type_desc, '' ) FROM  #gl_taxrepprn tr JOIN artxtype tt 
 ON tr.tax_type_code = tt.tax_type_code IF (@@error <>0)  BEGIN  SELECT @ret_val = 1 
 ROLLBACK TRAN  RETURN @ret_val  END END 
GO
GRANT EXECUTE ON  [dbo].[gl_taxrep_ar_prn_sp] TO [public]
GO
