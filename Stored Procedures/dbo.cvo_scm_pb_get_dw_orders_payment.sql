SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_scm_pb_get_dw_orders_payment]	@order_no int, 
													@order_ext int
AS
BEGIN

	SELECT dbo.ord_payment.order_no,   
         dbo.ord_payment.order_ext,   
         dbo.ord_payment.seq_no,   
         dbo.ord_payment.trx_desc,   
         dbo.ord_payment.date_doc,   
         dbo.ord_payment.payment_code,   
         dbo.ord_payment.amt_payment,   
         dbo.ord_payment.prompt1_inp,   
         dbo.ord_payment.prompt2_inp,   
         dbo.ord_payment.prompt3_inp,   
         dbo.ord_payment.prompt4_inp,   
         dbo.ord_payment.amt_disc_taken,   
         dbo.ord_payment.cash_acct_code,   
         dbo.arpymeth.prompt1,   
         dbo.arpymeth.prompt1_mask_id, 
         cast(null as datetime)     prompt1_date,  
         dbo.arpymeth.prompt2,   
         dbo.arpymeth.prompt2_mask_id,  
         cast(null as datetime) prompt2_date,
         dbo.arpymeth.prompt3,   
         dbo.arpymeth.prompt3_mask_id,   
         cast(null as datetime)    prompt3_date,
         dbo.arpymeth.prompt4,   
         dbo.arpymeth.prompt4_mask_id, 
         cast(null as datetime)     prompt4_date,  
         dbo.ord_payment.doc_ctrl_num  ,
		cast(null as char) csc_num,
		0 csc_visible,
		'N' approval_code
    FROM dbo.ord_payment
	left outer join dbo.arpymeth on dbo.ord_payment.payment_code = dbo.arpymeth.payment_code
	WHERE ( dbo.ord_payment.order_no = @order_no ) 
	AND   ( dbo.ord_payment.order_ext = @order_ext ) 
	ORDER BY dbo.ord_payment.seq_no ASC 
END
GO
GRANT EXECUTE ON  [dbo].[cvo_scm_pb_get_dw_orders_payment] TO [public]
GO
