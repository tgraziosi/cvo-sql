SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/

/* 
** Description		:  Create chargebacks
*/                      
     
                                                                                 
CREATE PROC [dbo].[ARProcessChargebacks_SP] @d_trx_num varchar( 16 ), @apply_num varchar(16), 
				    @customer varchar(8),  @chargeback_type varchar(8),
				    @debug_level smallint = 0

AS

/* Added chargeback to the following Declare statement  - The Emerald Group */ 

DECLARE  @last_chargeref varchar(16),  @cr_type smallint,  @apply_type smallint, 
	 @sequence_id int,  @min_chargeref varchar(16),  @chargeamt float, @chargeref varchar(16),
	 @result int, @cb_reason_code varchar(8), @cb_responsibility_code varchar(8),
	 @store varchar(16),
	@cb_reason_desc varchar(40),
	@cm_flag int,
	@total_chargebacks float

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arpchgbk.sp" + ", line " + STR( 1, 5 ) + " -- ENTRY: "

 SELECT @chargeref=" "
 SELECT @last_chargeref = ""
 SELECT @total_chargebacks = 0
 

 /*temp table to read information from both tables arinppdt = for charge backs on line details, and archbk for chrge backs on header*/
	CREATE TABLE #archgbk_arinppdt 
		(
			trx_ctrl_num varchar(16)  NULL,
			chargeref varchar(16)  NULL, 
			chargeamt float DEFAULT 0.0 NULL,
	 		cb_reason_code varchar(8) NULL, 
			cb_responsibility_code varchar(8) NULL, 
			store_number varchar(16) NULL,
			apply_to_num varchar(16) NULL,
			nat_cur_code varchar(8) NULL,
			credit_memo smallint DEFAULT 0 NULL,
			cb_reason_desc varchar(40) NULL,
			customer_code varchar(8) NULL,
			doc_ctrl_num varchar(16) NULL
		)
/*set rowcount in order to read all the data on the tables*/		
 SET ROWCOUNT 0
 		INSERT #archgbk_arinppdt 
				(trx_ctrl_num,				chargeref,				chargeamt,			cb_reason_code,
				cb_responsibility_code,		store_number,			apply_to_num,		nat_cur_code,
				credit_memo,				cb_reason_desc,			customer_code,		doc_ctrl_num)
			(SELECT 
				pdt.trx_ctrl_num,			pdt.chargeref, 			pdt.chargeamt,		pdt.cb_reason_code,
				pdt.cb_responsibility_code,	pdt.cb_store_number,	pdt.apply_to_num,	pdt.inv_cur_code,
				0 AS cb_credit_memo,		pdt.cb_reason_desc,		pdt.customer_code,	pdt.doc_ctrl_num
			FROM arinppdt pdt
				INNER JOIN arinppyt pyt ON pyt.trx_ctrl_num = pdt.trx_ctrl_num
				WHERE pdt.trx_ctrl_num = @d_trx_num AND pdt.chargeback = 1)


		INSERT #archgbk_arinppdt 
				(trx_ctrl_num,			chargeref,			chargeamt,		cb_reason_code,
				cb_responsibility_code,	store_number,		apply_to_num,	nat_cur_code,
				credit_memo,			cb_reason_desc,		customer_code,	doc_ctrl_num)
			(SELECT 
				trx_ctrl_num,			chargeref,			chargeamt,		cb_reason_code,
				cb_responsibility_code,	store_number,		apply_to_num,	nat_cur_code,	
				credit_memo,			cb_reason_desc,		customer_code,	doc_ctrl_num
				FROM archgbk
				WHERE trx_ctrl_num = @d_trx_num)

/*end temp table to read information from both tables arinppdt = for charge backs on line details, and archbk for chrge backs on header*/
 
 WHILE ( 1=1 )  
	BEGIN      
 		IF ( @debug_level > 1 ) SELECT "tmp/arpchgbk.sp " + CONVERT(char(16), @d_trx_num)

		/* Get the lowest chargeref */
		SELECT 	@min_chargeref = MIN(chargeref)  
		FROM 	#archgbk_arinppdt
		WHERE 	trx_ctrl_num = @d_trx_num  
		AND 	chargeref > @last_chargeref
		AND 	round(chargeamt, 2) <> 0 
		IF ( @@error != 0 ) 
			BEGIN  
				IF ( @debug_level > 1 ) SELECT "tmp/arpchgbk.sp" + ", line " + STR( 1, 5 ) + " -- EXIT: " 
 				RETURN 1 
			END		
				
		IF @min_chargeref IS NULL
		BEGIN
			BREAK
		END

 		IF ( @debug_level > 1 ) SELECT "tmp/arpchgbk.sp " + CONVERT(char(16), @d_trx_num) + " " + CONVERT(char(16),@min_chargeref)

		SELECT @chargeref = NULL
		SELECT @cb_reason_code = NULL
		SELECT @cb_responsibility_code = NULL
		SELECT @store = NULL

		SELECT @cm_flag = 0


		/* Get the record with the lowest chargeref */
 		SELECT 	@chargeamt = round(chargeamt, 2),
			@chargeref = chargeref, 
			@cb_reason_code = cb_reason_code,
		    @cb_responsibility_code = cb_responsibility_code, 
			@store = store_number, 
			@apply_num = apply_to_num,
			@cb_reason_desc = cb_reason_desc,
			@cm_flag = isnull(credit_memo ,0)
		FROM 	#archgbk_arinppdt  
		WHERE 	trx_ctrl_num = @d_trx_num 
		AND	chargeref = @min_chargeref          
		IF ( @@error != 0 ) 
			BEGIN  
				IF ( @debug_level > 1 ) SELECT "tmp/arpchgbk.sp" + ", line " + STR( 2, 5 ) + " -- EXIT: " 
 				BREAK
			END			

		SELECT @last_chargeref = @chargeref

		IF @cm_flag = 0 or @cm_flag IS NULL
		BEGIN
		
			/* Set the type */
			If @apply_num = "" or @apply_num = " " or @apply_num IS NULL
				SELECT @cr_type=2111, @apply_type=2111, @chargeback_type = "CHECK"
			Else
			BEGIN
				SELECT @cr_type=2111, @chargeback_type = "INVOICE"
				SELECT 	@apply_type=trx_type
				FROM	artrx
				WHERE	doc_ctrl_num=@apply_num
			END

			/* If the chargeback value is positive then create a chargeback invoice, if negative
			   create a chargeback credit memo */
			If @chargeamt > 0
			BEGIN
				EXEC @result = archgbk_sp @cr_type, @d_trx_num, @apply_type, @apply_num, 
					  		@chargeamt, @chargeref, @chargeback_type, @customer,
					  		@cb_reason_code, @cb_responsibility_code, @store, @debug_level,
							@cb_reason_desc
			END
			Else
				EXEC @result = arcbcrm_sp @cr_type, @d_trx_num, @chargeamt, @chargeref, @customer,
						  	@cb_reason_code, @cb_responsibility_code, @store, @debug_level,
							@cb_reason_desc

			IF (@result <> 0 ) 
			BEGIN  
				IF ( @debug_level > 1 ) SELECT "tmp/arpchgbk.sp" + ", line " + STR( 3, 5 ) + " -- EXIT: " 
 				RETURN 1 
			END
		END 
		ELSE
			EXEC @result = arcbcred_sp	@d_trx_num, @chargeamt, @chargeref, @customer,
					  		@debug_level
							
		IF @apply_num = "" or @apply_num = " " or @apply_num IS NULL
			SELECT @total_chargebacks = @total_chargebacks + @chargeamt
	END

UPDATE arcbtot
SET total_chargebacks = @total_chargebacks
WHERE trx_ctrl_num = @d_trx_num  
SET ROWCOUNT 1
DROP TABLE #archgbk_arinppdt
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ARProcessChargebacks_SP] TO [public]
GO
