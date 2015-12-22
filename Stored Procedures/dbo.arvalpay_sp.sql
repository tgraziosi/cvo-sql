SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 27/09/2013 - Issue #927 - Buying Group Switching - Remove old mod as this introduces duplicates      
CREATE PROC [dbo].[arvalpay_sp] @cust_code varchar(8)        
AS        
BEGIN        
	DECLARE @pay_sold_code varchar(8),        
			@across_na_flag smallint,        
			@arcust_pay_sold_code varchar(8),        
			@arcust_across_na_flag smallint,        
			@rel_tiered_flag smallint,        
			@arco_pay_sold_code varchar(8),        
			@arco_across_na_flag smallint,        
			@valid_payer_flag smallint,        
			@tlevel smallint,        
			@parent_cust varchar(8),        
			@inactive_cust smallint        
        
        
	SELECT	@arcust_pay_sold_code = NULL,        
			@arcust_across_na_flag = 0,        
			@rel_tiered_flag = 0,        
			@arco_pay_sold_code = NULL,        
			@arco_across_na_flag = 0,        
			@valid_payer_flag = 0,        
			@tlevel = 0,        
			@inactive_cust = 0         
        
	SELECT	@inactive_cust = ISNULL(status_type,0),           
			@valid_payer_flag = valid_payer_flag        
	FROM	arcust (NOLOCK)        
	WHERE	customer_code = @cust_code        
                
	IF ( @inactive_cust = 2 )        
		RETURN        
	   
	SELECT	@arcust_pay_sold_code = payer_soldto_rel_code,         
			@arcust_across_na_flag = ISNULL(across_na_flag,0)         
	FROM	arcust (NOLOCK)        
	WHERE	customer_code = @cust_code         
        
	SELECT	@arco_pay_sold_code = payer_soldto_rel_code,        
			@arco_across_na_flag = ISNULL(across_na_flag,0)         
	FROM	arco (NOLOCK)        
                        
	IF ( ( LTRIM(@arcust_pay_sold_code) IS NOT NULL AND LTRIM(@arcust_pay_sold_code) != ' ' ) )        
		SELECT	@rel_tiered_flag = tiered_flag         
		FROM	arrelcde (NOLOCK)       
		WHERE	relation_code = @arcust_pay_sold_code        
	ELSE        
		IF ( ( LTRIM(@arco_pay_sold_code) IS NOT NULL AND LTRIM(@arco_pay_sold_code) != ' ' ) )        
			SELECT	@rel_tiered_flag = tiered_flag         
			FROM	arrelcde (NOLOCK)        
			WHERE	relation_code = @arco_pay_sold_code                       
        
	IF (( ( LTRIM(@arcust_pay_sold_code) IS NULL OR LTRIM(@arcust_pay_sold_code) = ' ' )) AND ( ( LTRIM(@arco_pay_sold_code) IS NULL OR LTRIM(@arco_pay_sold_code) = ' ' ) ))        
	BEGIN        
         
		SET ROWCOUNT 1        
         
		SELECT	@pay_sold_code = relation_code,        
				@rel_tiered_flag = 1,        
				@tlevel = tier_level        
		FROM	artierrl (NOLOCK)       
		WHERE	rel_cust = @cust_code         
         
		SET ROWCOUNT 0        
	END        
	ELSE        
		IF (( LTRIM(@arcust_pay_sold_code) IS NOT NULL AND LTRIM(@arcust_pay_sold_code) != ' ' ))         
		BEGIN        
			SELECT	@tlevel = ISNULL(tier_level,0)        
			FROM	artierrl (NOLOCK)       
			WHERE	relation_code = @arcust_pay_sold_code        
			AND		rel_cust = @cust_code        
         
			SELECT	@pay_sold_code = @arcust_pay_sold_code         
        END         
		ELSE        
			IF (( LTRIM(@arco_pay_sold_code) IS NOT NULL AND LTRIM(@arco_pay_sold_code) != ' ' ))         
			BEGIN        
				SELECT	@tlevel = ISNULL(tier_level,0)        
				FROM	artierrl (NOLOCK)        
				WHERE	relation_code = @arco_pay_sold_code        
				AND		rel_cust = @cust_code        
				     
				SELECT @pay_sold_code = @arco_pay_sold_code         
			END         
                   
	IF (( LTRIM(@arcust_pay_sold_code) IS NOT NULL AND LTRIM(@arcust_pay_sold_code) != ' ' ))         
		SELECT @across_na_flag = @arcust_across_na_flag         
	ELSE         
		SELECT @across_na_flag = @arco_across_na_flag         
        
        
	TRUNCATE TABLE #arvpay        
        
        
	INSERT	#arvpay         
	SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
	FROM	arcust (NOLOCK)        
	WHERE	arcust.customer_code = @cust_code        
               
	IF (@valid_payer_flag=0)        
		RETURN        
        
	IF @across_na_flag = 0        
	BEGIN        
		IF @rel_tiered_flag = 0        
			INSERT	#arvpay         
			SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
			FROM	arcust (NOLOCK), arnarel (NOLOCK)        
			WHERE	customer_code = child         
			AND		parent = @cust_code        
			AND		relation_code = @pay_sold_code        
			AND		customer_code != @cust_code        
		ELSE        
			IF ( @tlevel = 1 )   
			BEGIN     
				INSERT	#arvpay  
				SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
				FROM	arcust (NOLOCK), artierrl (NOLOCK)        
				WHERE	customer_code = rel_cust        
				AND		relation_code = @pay_sold_code         
				AND		parent = @cust_code         
				AND		tier_level <> @tlevel         
				AND		customer_code != @cust_code        
			END
			ELSE        
				IF ( @tlevel = 2 )        
					INSERT	#arvpay         
					SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
					FROM	arcust (NOLOCK), artierrl (NOLOCK)       
					WHERE	customer_code = rel_cust        
					AND		relation_code = @pay_sold_code         
					AND		child_1 = @cust_code         
					AND		tier_level <> @tlevel        
					AND		customer_code != @cust_code        
				ELSE        
					 IF ( @tlevel = 3 )        
						 INSERT	#arvpay         
						 SELECT DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
						 FROM	arcust (NOLOCK), artierrl (NOLOCK)       
						 WHERE	customer_code = rel_cust        
						 AND	relation_code = @pay_sold_code         
						 AND	child_2 = @cust_code         
						 AND	tier_level <> @tlevel        
						 AND	customer_code != @cust_code        
					ELSE        
						IF ( @tlevel = 4 )        
							INSERT	#arvpay         
							SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
							FROM	arcust (NOLOCK), artierrl (NOLOCK)      
							WHERE	customer_code = rel_cust        
							AND		relation_code = @pay_sold_code         
							AND		child_3 = @cust_code         
							AND		tier_level <> @tlevel        
							AND		customer_code != @cust_code        
						ELSE        
							IF ( @tlevel = 5 )        
								INSERT	#arvpay         
								SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
								FROM	arcust (NOLOCK), artierrl (NOLOCK)        
								WHERE	customer_code = rel_cust        
								AND		relation_code = @pay_sold_code         
								AND		child_4 = @cust_code         
								AND		tier_level <> @tlevel        
								AND		customer_code != @cust_code        
								ELSE        
									IF ( @tlevel = 6 )        
										INSERT	#arvpay         
										SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
										FROM	arcust (NOLOCK), artierrl (NOLOCK)        
										WHERE	customer_code = rel_cust        
										AND		relation_code = @pay_sold_code         
										AND		child_5 = @cust_code         
										AND		tier_level <> @tlevel        
										AND		customer_code != @cust_code        
									ELSE        
										IF ( @tlevel = 7 )        
											INSERT	#arvpay         
											SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
											FROM	arcust (NOLOCK), artierrl (NOLOCK)        
											WHERE	customer_code = rel_cust        
											AND		relation_code = @pay_sold_code         
											AND		child_6 = @cust_code         
											AND		tier_level <> @tlevel        
											AND		customer_code != @cust_code        
										ELSE        
											IF ( @tlevel = 8 )        
												INSERT	#arvpay         
												SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
												FROM	arcust (NOLOCK), artierrl (NOLOCK)       
												WHERE	customer_code = rel_cust        
												AND		relation_code = @pay_sold_code         
												AND		child_7 = @cust_code         
												AND		tier_level <> @tlevel        
												AND		customer_code != @cust_code        
											ELSE        
												IF ( @tlevel = 9 )        
													INSERT	#arvpay         
													SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
													FROM	arcust (NOLOCK), artierrl (NOLOCK)        
													WHERE	customer_code = rel_cust        
													AND		relation_code = @pay_sold_code         
													AND		child_8 = @cust_code         
													AND		tier_level <> @tlevel        
													AND		customer_code != @cust_code        
												ELSE        
													IF ( @tlevel = 10 )        
														INSERT	#arvpay         
														SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
														FROM	arcust (NOLOCK), artierrl (NOLOCK)        
														WHERE	customer_code = rel_cust        
														AND		relation_code = @pay_sold_code         
														AND		child_9 = @cust_code         
														AND		tier_level <> @tlevel        
														AND		customer_code != @cust_code        
  
      
	END        
	ELSE         
	BEGIN        
         
		SELECT	@parent_cust = parent        
		FROM	artierrl (NOLOCK)       
		WHERE	rel_cust = @cust_code        
		AND		relation_code = @pay_sold_code        
		    
		INSERT	#arvpay         
		SELECT	DISTINCT customer_code, customer_name, bal_fwd_flag, 0        
		FROM	arcust (NOLOCK), artierrl (NOLOCK)       
		WHERE	customer_code = rel_cust        
		AND		relation_code = @pay_sold_code         
		AND		parent = @parent_cust        
		AND		customer_code != @cust_code -- v1.0 --  MOD 001  PSALINAS 09/09/2010    
		AND		customer_code = @cust_code        
  
	END 
END
GO
GRANT EXECUTE ON  [dbo].[arvalpay_sp] TO [public]
GO
