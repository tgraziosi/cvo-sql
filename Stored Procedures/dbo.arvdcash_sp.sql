
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




































































































































































  



					  

























































 




























































































































































































































































































CREATE PROC [dbo].[arvdcash_sp]
        @trx_ctrl_num varchar(16),
        @doc_ctrl_num varchar(16),
        @cust_code  varchar(8),
        @void_type  smallint
AS
DECLARE           @void_flag  smallint, @non_ar_flag smallint


SELECT @non_ar_flag = non_ar_flag 
FROM artrx
WHERE   doc_ctrl_num = @doc_ctrl_num
AND   customer_code = @cust_code





SELECT @void_flag = ABS(SIGN(@void_type - 3))

IF @non_ar_flag = 1 
BEGIN

	TRUNCATE TABLE #arnonardet

	INSERT #arnonardet
	(
	trx_ctrl_num,	sequence_id,	line_desc,
	tax_code,    	gl_acct_code,	unit_price,
    	extended_price, reference_code,	amt_tax,
	qty_shipped,	org_id
	)
	SELECT 	
	@trx_ctrl_num,	a.sequence_id,	a.line_desc,
	a.tax_code,    	a.gl_acct_code,	a.unit_price,
    	a.extended_price, a.reference_code,	a.amt_tax,
	a.qty_shipped, a.org_id
	FROM artrxndet a, artrx b
	WHERE   a.trx_ctrl_num = b.trx_ctrl_num
	AND   b.doc_ctrl_num = @doc_ctrl_num
	AND   b.customer_code = @cust_code
	AND   a.trx_type = 2111			

END
ELSE
BEGIN
	



	INSERT #arinppdt4720 
	    (
	    trx_ctrl_num,     doc_ctrl_num,
	    sequence_id,      trx_type,
	    apply_to_num,     apply_trx_type,
	    customer_code,    date_aging,
	    amt_applied,      amt_disc_taken,
	    wr_off_flag,      amt_max_wr_off,
	    void_flag,      line_desc,
	    sub_apply_num,    sub_apply_type,
	    amt_tot_chg,        amt_paid_to_date,     
	    terms_code,       posting_code,  
	    date_doc,     amt_inv,       
	    gain_home,        gain_oper,
	    inv_amt_applied,    inv_amt_disc_taken,
	    inv_amt_max_wr_off,   inv_cur_code,
	    writeoff_code, org_id
	    )
	SELECT    @trx_ctrl_num,    @doc_ctrl_num,
	    pdt.sequence_id,    2121, 
	    pdt.apply_to_num,   pdt.apply_trx_type,
	    pdt.customer_code,    pdt.date_aging,
	    pdt.amt_applied,    pdt.amt_disc_taken,
	    SIGN(pdt.amt_wr_off), pdt.amt_wr_off,     
	    @void_flag,     pdt.line_desc,
	    pdt.sub_apply_num,    pdt.sub_apply_type,
	    age.amount,     age.amt_paid,
	    '',       '',
	    age.date_doc,     age.amount,
	    pdt.gain_home,    pdt.gain_oper,
	    pdt.inv_amt_applied,    pdt.inv_amt_disc_taken,
	    pdt.inv_amt_wr_off,   pdt.inv_cur_code,
	    pdt.writeoff_code, pdt.org_id
	FROM    artrxpdt pdt, artrx trx, artrxage age                           
	WHERE   pdt.trx_ctrl_num = trx.trx_ctrl_num
	AND   pdt.trx_type = trx.trx_type
	AND   pdt.trx_type = 2111
	AND   pdt.void_flag = 0
	AND   pdt.sub_apply_num = age.doc_ctrl_num
	AND   pdt.sub_apply_type = age.trx_type
	AND   pdt.date_aging = age.date_aging
	AND   trx.doc_ctrl_num = @doc_ctrl_num
	AND   trx.customer_code = @cust_code

	UPDATE #arinppdt4720
	SET void_flag = 1
	FROM  arinppdt pdt
	WHERE #arinppdt4720.trx_ctrl_num = pdt.trx_ctrl_num
	AND #arinppdt4720.sequence_id = pdt.sequence_id
END

GO

GRANT EXECUTE ON  [dbo].[arvdcash_sp] TO [public]
GO
