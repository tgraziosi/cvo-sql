SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateTrxsForSumActivitis_sp]
(
	@process_ctrl_num			smProcessCtrlNum,  		
	@batch_code					smBatchCode,	   		
	@user_id					smUserID,		   		
	@company_code				smCompanyCode,	   		
	@journal_type				smJournalType,			
	@home_currency_code			smCurrencyCode,			
	@precision		 			smallint,				
	@debug_level				smDebugLevel 	= 0		
)						
AS 

DECLARE 
	@result						smErrorCode,
	@message					smErrorLongDesc,
	@journal_ctrl_num			smControlNumber,
	@date_entered          	 	smJulianDate,
	@date_applied           	smJulianDate,
	@apply_date					datetime,
	@co_trx_id					smSurrogateKey,
	@trx_type               	smTrxType,				
	@gl_trx_type               	smallint,				
	@sequence_id				smCounter,
	@account_id					smSurrogateKey,
	@account_code	  			smAccountCode,
	@account_reference_code	  	smAccountReferenceCode,
	@amount		  				smMoneyZero,
	@trx_description			smStdDescription,
	@doc_reference				varchar(16)	,
	@entry_date					datetime,
	@ib_org_id                             	varchar(30), 
	@ib_org_id_det                        	varchar(30),  
	@asset_org_id				varchar(30)	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "AMCTSACT.cpp" + ", line " + STR( 102, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT	"Currency Precision = " + CONVERT(char(20), @precision) 
	   





SELECT DISTINCT apply_date,trx_type, asset_org_id	
INTO	#amsumhdr
FROM	#amsumactval


SELECT @asset_org_id = MIN(isnull(asset_org_id, '')) 	
FROM	#amsumhdr
WHILE (@asset_org_id IS NOT NULL)
BEGIN


SELECT 	@apply_date		= MIN(apply_date)
FROM	#amsumhdr
WHERE asset_org_id = @asset_org_id	
 

WHILE (@apply_date IS NOT NULL)
BEGIN


	SELECT @trx_type 	= MIN(trx_type)
	FROM	#amsumhdr
	WHERE	apply_date	= @apply_date
	AND asset_org_id = @asset_org_id	

	WHILE (@trx_type IS NOT NULL)
	BEGIN
								
			SELECT 	@journal_ctrl_num 	= NULL

			



			SELECT  @entry_date = MAX(last_modified_date)
			FROM 	#amacthdr
			WHERE	sum_val 	  = 1
			AND		post_to_gl	  = 1
			AND 	apply_date	  = @apply_date
			AND		trx_type	  = @trx_type
			AND asset_org_id = @asset_org_id		

			SELECT @date_entered = DATEDIFF(dd, "1/1/1980", @entry_date) + 722815


				
			SELECT 
				   	@date_applied 		= DATEDIFF(dd, "1/1/1980", apply_date) + 722815,
					@gl_trx_type 		= 10000 + @trx_type,	 
					@trx_description	= atd.trx_name,
					@doc_reference		= atd.trx_description
			FROM 	#amsumhdr 	ah,
					amtrxdef	atd
			WHERE 	apply_date 			= @apply_date
			AND		ah.trx_type			= @trx_type
			AND		atd.trx_type		= ah.trx_type
			AND asset_org_id = @asset_org_id			

				
			SELECT	@ib_org_id = @asset_org_id   
			IF @ib_org_id is null or @ib_org_id = ''
				SELECT	@ib_org_id = org_id     
		       	        FROM	amOrganization_vw       
			        WHERE	outline_num = '1'       

				
			EXEC @result = gltrxcrh_sp 
								@process_ctrl_num,
								-1,
								10000,
								2,
								@journal_type,
								@journal_ctrl_num OUTPUT,
								@trx_description,
								@date_entered,
								@date_applied,
								0,				
								0,				
								0,				
								@batch_code,		
								0,
								@company_code,		
								@company_code,
								@home_currency_code,
								"",					
								@gl_trx_type,
								@user_id,
								0,  			
								@debug = @debug_level,
								@ib_org_id= @ib_org_id,	 		
								@interbranch_flag = 0   

			 	
			IF @result <> 0
			 	RETURN @result

			




			UPDATE 	#amacthdr
			SET 	journal_ctrl_num 	= @journal_ctrl_num
			WHERE	apply_date		 	= @apply_date
			AND 	trx_type		 	= @trx_type
  			AND		post_to_gl			= 1
			AND 	sum_val    			= 1
			AND		((journal_ctrl_num IS NULL) OR (journal_ctrl_num = ""))
			AND asset_org_id = @asset_org_id		
			
			SELECT @result = @@error
	  		IF @result <> 0
				RETURN @result

			IF @debug_level >= 3
				SELECT	"Journal Ctrl Num = " + @journal_ctrl_num


				
			



			SELECT	@account_id 	= MIN(account_id)
			FROM	#amsumactval
			WHERE	apply_date		= @apply_date
			AND		trx_type		= @trx_type
			AND asset_org_id = @asset_org_id			

			WHILE @account_id IS NOT NULL
			BEGIN
					SELECT	@sequence_id 	= 0
					
					SELECT 								
							@account_code 			= account_code,
							@account_reference_code = account_reference_code,
							@amount 				= (SIGN(amount) * ROUND(ABS(amount) + 0.0000001, @precision))
					FROM 	#amsumactval  
					WHERE	apply_date			= @apply_date
					AND		trx_type			= @trx_type
					AND		account_id			= @account_id
					AND asset_org_id = @asset_org_id	

			 
			 		IF @debug_level >= 3
			 		BEGIN
			 			SELECT "Account Code           = " + @account_code
			 			SELECT "Account Reference Code = " + @account_reference_code
			 			SELECT "Amount                 = " + "$" + LTRIM(CONVERT(char(255), CONVERT(money, @amount)))
			 		END
					
					SELECT @ib_org_id_det = ISNULL(dbo.IBOrgbyAcct_fn(@account_code),'')   

			 		EXEC @result = gltrxcrd_sp 
										10000, 
										2,
										@journal_ctrl_num,
										@sequence_id 	OUTPUT,
										@company_code,		
										@account_code,
										"",					
										@doc_reference,		
										"",					
										@account_reference_code,
										@amount,
										@amount,			
										@home_currency_code,
										1,					
										@gl_trx_type,
										@account_id,
										@debug = @debug_level,
										@ib_org_id = @ib_org_id_det   

			  		IF @result <> 0
						RETURN @result

					SELECT	@account_id 	= MIN(account_id)
					FROM	#amsumactval
					WHERE	apply_date		= @apply_date
					AND 	trx_type		= @trx_type
					AND		account_id 		> @account_id
					AND asset_org_id = @asset_org_id			
					
					
				
			END
				
			


			EXEC @result = gltrxvfy_sp 
						  		@journal_ctrl_num,
								@debug_level  

			IF @result <> 0
				RETURN @result


					   
			SELECT	@trx_type		= MIN(trx_type)
			FROM	#amsumhdr
			WHERE	trx_type		> @trx_type
			AND		apply_date		= @apply_date
			AND asset_org_id = @asset_org_id			

	END

	SELECT	@apply_date		= MIN(apply_date)
	FROM	#amsumhdr
	WHERE	apply_date		> @apply_date
	AND asset_org_id = @asset_org_id			
	
END

SELECT @asset_org_id = MIN(isnull(asset_org_id, '')) 	
FROM	#amsumhdr
WHERE	asset_org_id > @asset_org_id		

END 		

DROP TABLE #amsumhdr

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "AMCTSACT.cpp" + ", line " + STR( 334, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCreateTrxsForSumActivitis_sp] TO [public]
GO
