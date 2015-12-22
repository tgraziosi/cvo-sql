SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_cncl.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROCEDURE [dbo].[eft_cncl_sp]
	@from_cash_acct_code	varchar( 32 ) = NULL,
	@thru_cash_acct_code	varchar( 32 ) = NULL,
	@from_vendor_code		varchar( 12 ) = NULL,
	@thru_vendor_code		varchar( 12 ) = NULL,
	@from_payment_num		varchar( 16 ) = NULL,
	@thru_payment_num		varchar( 16 ) = NULL

AS


SELECT @from_cash_acct_code = isnull( @from_cash_acct_code, ' ' ),
 @thru_cash_acct_code = isnull( @thru_cash_acct_code, ' ' ),
	 @from_vendor_code = isnull( @from_vendor_code, ' ' ),
	 @thru_vendor_code = isnull( @thru_vendor_code, ' ' ),
	 @from_payment_num = isnull( @from_payment_num, ' ' ),
	 @thru_payment_num = isnull( @thru_payment_num, ' ' )


CREATE TABLE #eft_pcnl
(
 payment_num varchar( 16 )
)


BEGIN TRANSACTION 


INSERT	#eft_pcnl
		( payment_num )
SELECT	distinct payment_num
FROM	eft_aptr
WHERE	cash_acct_code BETWEEN @from_cash_acct_code AND @thru_cash_acct_code
AND		vendor_code BETWEEN @from_vendor_code and @thru_vendor_code
AND		payment_num BETWEEN @from_payment_num AND @thru_payment_num
AND		process_flag = 0


IF ( @@rowcount = 0 )
BEGIN
	COMMIT TRANSACTION
	SELECT 0
	RETURN
END


DELETE
FROM	apaprtrx
WHERE	trx_ctrl_num IN ( SELECT payment_num
 FROM #eft_pcnl ) 


IF ( @@error != 0 )
BEGIN
	ROLLBACK TRANSACTION
	SELECT -1
	RETURN
END


DELETE
FROM	apinppdt
WHERE	trx_ctrl_num IN ( SELECT payment_num
						 FROM #eft_pcnl )


IF ( @@error != 0 )
BEGIN
	ROLLBACK TRANSACTION
	SELECT -1
	RETURN
END


DELETE
FROM apinppyt
WHERE trx_ctrl_num IN ( SELECT payment_num
 FROM #eft_pcnl )


IF ( @@error != 0 )
BEGIN
	ROLLBACK TRANSACTION
	SELECT -1
	RETURN
END


UPDATE apinppyt
SET print_batch_num = 0
FROM eft_aptr a, #eft_pcnl b, apinppyt c
WHERE a.payment_num = b.payment_num
AND a.doc_ctrl_num = c.trx_ctrl_num 
AND a.doc_ctrl_num IN ( SELECT trx_ctrl_num
 FROM apinppyt )
AND c.payment_type IN ( 2, 3 )


IF ( @@error != 0 )
BEGIN
	ROLLBACK TRANSACTION
	SELECT -1
	RETURN
END


DELETE
FROM eft_aptr
WHERE payment_num IN ( SELECT payment_num
 FROM #eft_pcnl )


IF ( @@error != 0 )
BEGIN
	ROLLBACK TRANSACTION
	SELECT -1
	RETURN
END


COMMIT TRANSACTION 


SELECT 1
GO
GRANT EXECUTE ON  [dbo].[eft_cncl_sp] TO [public]
GO
