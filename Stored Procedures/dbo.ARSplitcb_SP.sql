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
** Description		:  Split an existing chargeback into multiple chargebacks
*/       
                                                                                 
CREATE PROC [dbo].[ARSplitcb_SP] @d_trx_num varchar( 16 ), @apply_num varchar(16), 
				    @customer varchar(8), @debug_level smallint = 0

AS

/* Added chargeback to the following Declare statement  - The Emerald Group */ 

DECLARE  @last_chargeref varchar(16),  @cr_type smallint,  @apply_type smallint, 
	 @sequence_id int,  @min_chargeref varchar(16),  @chargeamt float, @chargeref varchar(16),
	 @result int, @cb_reason_code varchar(8), @cb_responsibility_code varchar(8), @store varchar(16)

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


 SELECT @chargeref=" "
 SELECT @last_chargeref = @chargeref
 
 WHILE ( @chargeref IS NOT NULL )  
	BEGIN      
		
		/* Get the lowest chargeref */
		SELECT @min_chargeref = MIN(chargeref)  FROM archgbk
		WHERE trx_ctrl_num = @d_trx_num  AND chargeref > @last_chargeref
		IF ( @@error != 0 ) 
			BEGIN  
				IF ( @debug_level > 1 ) SELECT "tmp/arsplitcb.sp" + ", line " + STR( 1, 5 ) + " -- EXIT: " 
 				RETURN 1 
			END		
	
		SELECT @chargeref = NULL
		SELECT @cb_reason_code = NULL
		SELECT @cb_responsibility_code = NULL
		SELECT @store = NULL

		/* Get the record with the lowest chargeref */
 		SELECT @chargeamt = chargeamt, @chargeref = chargeref, @cb_reason_code = cb_reason_code,
		       @cb_responsibility_code = cb_responsibility_code, @store = store_number,
/* Begin mod: CB0004- Add customer code */
		       @customer = customer_code  
/* End mod: CB0004 
read data fromt he new temp table  #archgbk_arinppdt*/ 
		FROM #archgbk_arinppdt  
		WHERE trx_ctrl_num = @d_trx_num AND
 		      chargeref = @min_chargeref                    
		IF ( @@error != 0 ) 
			BEGIN  
				IF ( @debug_level > 1 ) SELECT "tmp/arsplitcb.sp" + ", line " + STR( 2, 5 ) + " -- EXIT: " 
 				BREAK
			END			
		IF( @chargeref IS NULL )  BREAK  

		SELECT @last_chargeref = @chargeref, @cr_type=2111, @apply_type=2031

		EXEC @result = aradjcb_sp @cr_type, @d_trx_num, @apply_type, @apply_num, 
					  @chargeamt, @chargeref, @customer,
					  @cb_reason_code, @cb_responsibility_code, @store, @debug_level

	END
DROP TABLE #archgbk_arinppdt
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[ARSplitcb_SP] TO [public]
GO
