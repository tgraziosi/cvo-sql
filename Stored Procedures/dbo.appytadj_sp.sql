SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[appytadj_sp]
	@trx_ctrl_num   varchar(16),    
	@vendor_code    varchar(12),
	@doc_ctrl_num   varchar(16),	
	@void_type      smallint,
	@cash_acc       varchar(32)
AS

DECLARE @void_type2 smallint







IF EXISTS(SELECT * FROM #apinppdt3331 WHERE trx_ctrl_num = @trx_ctrl_num)
BEGIN
		IF (@void_type <> 4)
		    UPDATE #apinppdt3331
			SET void_flag = 1
			WHERE void_flag = 0
		RETURN
END







SELECT @void_type2 = NULL

SELECT @void_type2 = void_type
FROM apinppyt
WHERE trx_ctrl_num = @trx_ctrl_num
AND   trx_type     = 4112





IF ((@void_type <> 4) OR (@void_type2 <> 4))

BEGIN
	DELETE #apinppdt3331

	

                      
	INSERT  #apinppdt3331 (         
		trx_ctrl_num,   	trx_type,       sequence_id,
		apply_to_num,   	apply_trx_type, amt_applied,
		amt_disc_taken, 	line_desc,      void_flag,
		payment_hold_flag,  vendor_code,	vo_amt_applied,
		vo_amt_disc_taken,	gain_home,		gain_oper,
		nat_cur_code, org_id )
	SELECT
		@trx_ctrl_num,    	4112,             a.sequence_id,
		a.apply_to_num,   	4091, 			  a.amt_applied,
		a.amt_disc_taken, 	a.line_desc,      1,
		0,                	@vendor_code,	  a.vo_amt_applied,	
		a.vo_amt_disc_taken,a.gain_home,      a.gain_oper,
		b.currency_code, a.org_id
	FROM    appydet a, apvohdr b, appyhdr c
	WHERE   c.doc_ctrl_num = @doc_ctrl_num
	AND     c.vendor_code = @vendor_code
	AND		a.trx_ctrl_num = c.trx_ctrl_num
	AND     a.void_flag = 0
	AND		b.trx_ctrl_num = a.apply_to_num
	AND     c.cash_acct_code = @cash_acc

END
ELSE

BEGIN
	
	






	DELETE #apinppdt3331

	

                      
	INSERT  #apinppdt3331 (         
		trx_ctrl_num,   	trx_type,       sequence_id,
		apply_to_num,   	apply_trx_type, amt_applied,
		amt_disc_taken, 	line_desc,      void_flag,
		payment_hold_flag,  vendor_code,	vo_amt_applied,	
		vo_amt_disc_taken,	gain_home,		gain_oper,
		nat_cur_code, org_id )
	SELECT
		@trx_ctrl_num,    4112,             a.sequence_id,
		a.apply_to_num,   4091, 			a.amt_applied,
		a.amt_disc_taken, a.line_desc,      0,
		0,                @vendor_code,		vo_amt_applied,
		vo_amt_disc_taken,a.gain_home,      a.gain_oper,
		b.currency_code, a.org_id
	FROM    appydet a, apvohdr b, appyhdr c 
	WHERE   c.doc_ctrl_num = @doc_ctrl_num
	AND     c.vendor_code = @vendor_code
	AND		a.trx_ctrl_num = c.trx_ctrl_num
	AND     a.void_flag = 0
	AND		b.trx_ctrl_num = a.apply_to_num
	AND     c.cash_acct_code = @cash_acc

	UPDATE #apinppdt3331
	SET    void_flag = 1
	FROM   #apinppdt3331 a, apinppdt b
	WHERE  a.trx_ctrl_num = b.trx_ctrl_num
	AND    a.trx_type = b.trx_type
	AND    a.sequence_id = b.sequence_id

END

GO
GRANT EXECUTE ON  [dbo].[appytadj_sp] TO [public]
GO
