SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[arrefundcca_sp] 
AS
	
	DECLARE @trx_type			CHAR(2)
   	DECLARE	@processor			INT
	DECLARE @result				SMALLINT
        DECLARE @exist_adm                      SMALLINT
        DECLARE @order_str                      CHAR(16) 
        DECLARE @source_trx                     varchar(16)
	SELECT @trx_type= 'C7'

        SELECT @exist_adm = 0 
	SELECT @exist_adm = ISNULL( (SELECT 1 FROM sysobjects WHERE name = 'orders') , 0 )

	SELECT @processor = configuration_int_value
		FROM icv_config
		WHERE UPPER(configuration_item_name) = 'PROCESSOR INTERFACE'
    
        SELECT 'trx_type'
        SELECT @trx_type	
      
	
	 
	 INSERT #arccatransactions (	trx_ctrl_num,  		trx_type,	prompt1_inp, 
				 	prompt2_inp, 		prompt3_inp,	prompt4_inp,
					amt_payment, 		trx_code,
				 	new_prompt4_inp, 	nat_cur_code,	charged )
			SELECT		pyt.trx_ctrl_num,  	trx_type,	pyt.prompt1_inp, 
				 	pyt.prompt2_inp, 	pyt.prompt3_inp,	pyt.prompt4_inp,
					amt_payment, 		@trx_type,
					'',			pyt.nat_cur_code, 	9999
			 FROM	#arinppyt_work pyt
				 INNER JOIN arpymeth apm 
				 	ON pyt.payment_code = apm.payment_code 
				 INNER JOIN icv_cctype cc 
					ON pyt.payment_code = cc.payment_code 
			WHERE    LEN(pyt.prompt4_inp)>0

        --SELECT 'Dump #arinppyt_work'
      	--SELECT 'trx_ctrl_num = ' + trx_ctrl_num +
        --       ' doc_ctrl_num = ' + doc_ctrl_num +
        --       ' trx_type = '+ STR(trx_type ,5,0)	+
        --       ' void_type = ' + STR(void_type,5,0) +
        --       '  payment_type = ' + STR(payment_type ,5, 0) + 
        --       '  deposit_num  = ' + ISNULL(deposit_num, ' ') +
        --       '  source_trx_ctrl_num = ' + ISNULL(source_trx_ctrl_num , ' ') 
        --      	FROM	#arinppyt_work 

        SELECT @source_trx = ISNULL(source_trx_ctrl_num, '')  FROM #arinppyt_work

        IF (@source_trx)  <> ''
        BEGIN
          -- select 
          --     'artrx trx_ctrl_num = '+ a.trx_ctrl_num +
          --     '  artrx order_ctrl_num = ' + a.order_ctrl_num 
          --   from artrx a
          --   INNER JOIN #arinppyt_work pyt
	  --	 ON a.trx_ctrl_num = pyt.source_trx_ctrl_num
          --       and  a.trx_type = 2031

           select  @order_str = ISNULL(a.order_ctrl_num ,'')
             from artrx a
             INNER JOIN #arinppyt_work pyt
		 ON a.trx_ctrl_num = pyt.source_trx_ctrl_num
                 and  a.trx_type = 2031
        END


	DELETE #arccatransactions 
	FROM #arccatransactions	a
		INNER JOIN #ewerror b
		ON	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.trx_type = 2111

		
	DELETE #arccatransactions
	FROM #arccatransactions	a
		INNER JOIN #arinppyt_work pyt
			 ON a.trx_ctrl_num = pyt.trx_ctrl_num
			   AND a.trx_type= pyt.trx_type
		WHERE pyt.void_type = 3
	
        IF(@order_str) <> '' AND (@exist_adm = 1)
        BEGIN
            --SELECT 'DELETE ' + @order_str + 'FROM #arccatransactions'
       	    DELETE #arccatransactions
	     FROM #arccatransactions	a
		INNER JOIN #arinppyt_work pyt
			 ON a.trx_ctrl_num = pyt.trx_ctrl_num
			   AND a.trx_type= pyt.trx_type
                INNER JOIN artrx trx
                         ON trx.trx_ctrl_num = pyt.source_trx_ctrl_num
                         and  trx.trx_type = 2031 and
                         trx.order_ctrl_num = @order_str 
        END	

	IF @processor = 1
			BEGIN
				EXEC @result = icv_trustmarque_charge_sp

			END

	IF @processor = 2
			BEGIN
				EXEC @result = icv_verisign_charge_sp

			END
	

  RETURN 0
GO
GRANT EXECUTE ON  [dbo].[arrefundcca_sp] TO [public]
GO
