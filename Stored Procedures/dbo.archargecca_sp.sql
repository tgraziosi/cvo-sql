SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


/*
**	Name of	Stored Procedure : archargecca_sp
**	Purpose	: Charge credit card when the user try to post a cash receipts
**	Completion Date	& Author : Cyanez 01/03/2004
  
**
**
**						Confidential Information
**			Limited	Distribution to	Authorized Persons Only
**			Created	1995 and Protected as Unpublished Work
**					Under the U.S. Copyright Act of	1976
**			Copyright (c) Platinum Software	Corporation, 1995
**							All	Rights Reserved
**
**	Tables involved:
**		Read:
**		Write:
**
**
**   	Rev. 	Name		DATE		 	Why 
**  	******	**********	**********		**************
**	1.1	CBalderas	14-Aug-08		SCR 37669: join and rleationship with arinppyt to post without errors
**								a Cash Receipt with payment method as CCA.

*/                           

CREATE PROC [dbo].[archargecca_sp] 
AS
	
	DECLARE @trx_type			CHAR(2)
   	DECLARE	@processor			INT
	DECLARE @result				SMALLINT

	IF EXISTS (SELECT 1 FROM arco WHERE ISNULL(authorize_onsave,0)=0)
		BEGIN
			SELECT @trx_type= 'C1'
		END
	ELSE
		BEGIN
			SELECT @trx_type= 'CO'
		END

	/* Get the processor */
	SELECT @processor = configuration_int_value
		FROM icv_config
		WHERE UPPER(configuration_item_name) = 'PROCESSOR INTERFACE'
	

	 /* Insert for payments with CC Paymenth Method */
	 if (@trx_type = 'C1')
	 begin
		 INSERT #arccatransactions (	trx_ctrl_num,  		trx_type,	prompt1_inp, 
				 		prompt2_inp, 		prompt3_inp,	prompt4_inp,
						amt_payment, 		trx_code,
				 		new_prompt4_inp, 	nat_cur_code,	charged )
				SELECT		pyt.trx_ctrl_num,  	pyt.trx_type,	pyt.prompt1_inp, 
				 		pyt.prompt2_inp, 	pyt.prompt3_inp,	pyt.prompt4_inp,
						pyt.amt_payment, 	@trx_type,
						'',			pyt.nat_cur_code, 	9999
				 FROM	#arinppyt_work pyt
					 INNER JOIN arpymeth apm 
				 		ON pyt.payment_code = apm.payment_code 
					 INNER JOIN icv_cctype cc 
						ON pyt.payment_code = cc.payment_code 
					 INNER JOIN arinppyt pyt2
						ON pyt.trx_ctrl_num = pyt2.trx_ctrl_num AND
						   pyt.trx_type = pyt2.trx_type
				WHERE (pyt2.prompt4_inp = '')
	 end
	else
	 begin
		 INSERT #arccatransactions (	trx_ctrl_num,  		trx_type,	prompt1_inp, 
				 		prompt2_inp, 		prompt3_inp,	prompt4_inp,
						amt_payment, 		trx_code,
				 		new_prompt4_inp, 	nat_cur_code,	charged )
				SELECT		pyt.trx_ctrl_num,  	pyt.trx_type,	pyt.prompt1_inp, 
				 		pyt.prompt2_inp, 	pyt.prompt3_inp,	pyt.prompt4_inp,
						pyt.amt_payment, 	@trx_type,
						'',			pyt.nat_cur_code, 	9999
				 FROM	#arinppyt_work pyt
					 INNER JOIN arpymeth apm 
				 		ON pyt.payment_code = apm.payment_code 
					 INNER JOIN icv_cctype cc 
						ON pyt.payment_code = cc.payment_code 
					
	end
	/* Dont try to charge documents with errors */ 
	DELETE #arccatransactions 
	FROM #arccatransactions	a
		INNER JOIN #ewerror b
		ON	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.trx_type = 2111


	/* Delete Invoice Payments that comes from ADM sales order */

	DELETE #arccatransactions
		FROM #arccatransactions	a
		INNER JOIN #arinppyt_work pyt
			 ON a.trx_ctrl_num = pyt.trx_ctrl_num
			   AND a.trx_type= pyt.trx_type
		INNER JOIN artrx h
			 ON pyt.source_trx_ctrl_num = h.trx_ctrl_num
			   AND pyt.source_trx_type = h.trx_type
		WHERE LEN(ISNULL(h.order_ctrl_num,'')) <> 0

	/* Do not charge on account documents or adjustments with void type = 3 (Void Applied Payments) */

	DELETE #arccatransactions
		FROM #arccatransactions	a
		INNER JOIN #arinppyt_work pyt
			 ON a.trx_ctrl_num = pyt.trx_ctrl_num
			   AND a.trx_type= pyt.trx_type
		WHERE pyt.payment_type IN (2, 4)

		
	/* Charge the CC */
	IF @processor = 1
			BEGIN
				EXEC @result = icv_trustmarque_charge_sp

			END

	IF @processor = 2
			BEGIN
				EXEC @result = icv_verisign_charge_sp

			END
	

	IF EXISTS (SELECT 1 FROM arco WHERE ISNULL(authorize_onsave,0)=0)
		BEGIN
			UPDATE icv_ccinfo
				SET  	prompt1 = t.prompt1_inp,
					prompt2 = t.prompt2_inp,
					prompt3 = t.prompt3_inp,
					trx_ctrl_num = t.trx_ctrl_num,
					trx_type  = t.trx_type,
					order_no  = 0,
					order_ext = 0
			FROM icv_ccinfo i
				INNER JOIN #arinppyt_work a
					ON  i.payment_code = a.payment_code 
					AND  i.customer_code = a.customer_code 
				INNER JOIN #arccatransactions t
					ON t.trx_ctrl_num = a.trx_ctrl_num
					AND  t.trx_type = a.trx_type
					AND t.charged = 0
		END

  RETURN 0
GO
GRANT EXECUTE ON  [dbo].[archargecca_sp] TO [public]
GO
