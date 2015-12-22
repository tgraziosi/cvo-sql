SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateTrxsForActivities_sp]
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
	@trx_ctrl_num				smControlNumber,
	@journal_ctrl_num			smControlNumber,
	@date_entered 	 	smJulianDate,
	@date_applied 	smJulianDate,
	@co_asset_book_id			smSurrogateKey,
	@co_trx_id					smSurrogateKey,
	@trx_type 	smTrxType,				
	@gl_trx_type 	smallint,				
	@sequence_id				smCounter,
	@account_id					smSurrogateKey,
	@account_type_id 			smAccountTypeID,
	@account_code	 			smAccountCode,
	@account_reference_code	 	smAccountReferenceCode,
	@amount		 				smMoneyZero,
	@trx_description			smStdDescription,
	@doc_reference				varchar(16),
	@ib_org_id                             	varchar(30), 
	@ib_org_id_det                        	varchar(30)  
	, @original_org_id                      varchar(30), 	
	@ib_flag_changed			smallint	

        select @ib_org_id    ='',@ib_org_id_det=''   
	select @ib_flag_changed = 0		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amctfact.sp" + ", line " + STR( 92, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT	"Currency Precision = " + CONVERT(char(20), @precision) 
	 

SELECT 	@co_trx_id 		= MIN(co_trx_id)
FROM	#amacthdr
WHERE sum_val = 0
WHILE (@co_trx_id IS NOT NULL)

BEGIN
	select @trx_ctrl_num = trx_ctrl_num
	from amtrxhdr where co_trx_id = @co_trx_id 

	IF EXISTS (SELECT	account_id
				FROM	#amactval
				WHERE	co_trx_id	= @co_trx_id)
	BEGIN
	
		SELECT 	@journal_ctrl_num 	= NULL
		
		SELECT 
			 	@co_asset_book_id	= co_asset_book_id,
			 	@date_entered 		= DATEDIFF(dd, "1/1/1980", last_modified_date) + 722815,
				@date_applied 		= DATEDIFF(dd, "1/1/1980", apply_date) + 722815,
				@trx_type 			= trx_type,	 
				@gl_trx_type 		= 10000 + trx_type,	 
				@trx_description	= trx_description,
				@doc_reference		= doc_reference,
				@ib_org_id		= asset_org_id	
		FROM 	#amacthdr
		WHERE 	co_trx_id 			= @co_trx_id
		AND		post_to_gl			= 1			
			
		
		
		IF @ib_org_id is null 
			SELECT	@ib_org_id = org_id FROM amOrganization_vw       
		        WHERE	outline_num = '1'      
		

		SELECT @original_org_id = @ib_org_id		

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
						@trx_ctrl_num,					
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
		WHERE 	co_trx_id 			= @co_trx_id 
		AND		post_to_gl			= 1

		SELECT @result = @@error
	 	IF @result <> 0
			RETURN @result

		IF @debug_level >= 3
			SELECT	"Journal Ctrl Num = " + @journal_ctrl_num

		SELECT	@account_type_id 	= MIN(account_type_id)
		FROM	#amactval
		WHERE	co_trx_id			= @co_trx_id

		WHILE @account_type_id IS NOT NULL
		BEGIN
			SELECT	@sequence_id 	= 0
			
			SELECT 
					@account_id				= account_id,
					@account_code 			= account_code,
					@account_reference_code = account_reference_code,
					@amount 				= (SIGN(amount) * ROUND(ABS(amount) + 0.0000001, @precision))
			FROM 	#amactval 
			WHERE 	co_trx_id 				= @co_trx_id
			AND		account_type_id			= @account_type_id

	 
	 		IF @debug_level >= 3
	 		BEGIN
	 			SELECT "Account Code           = " + @account_code
	 			SELECT "Account Reference Code = " + @account_reference_code
	 			SELECT "Amount                 = " + "$" + LTRIM(CONVERT(char(255), CONVERT(money, @amount)))
	 		END

			SELECT @ib_org_id_det = ISNULL(dbo.IBOrgbyAcct_fn(@account_code),'') 
			
			IF @original_org_id <> @ib_org_id_det 	
				SELECT @ib_flag_changed = 1	
				
	 		EXEC @result = gltrxcrd_sp 
								10000, 
								2,
								@journal_ctrl_num,
								@sequence_id 	OUTPUT,
								@company_code,		
								@account_code,
								@trx_description,					
								@doc_reference,		
								@trx_ctrl_num,					
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


			SELECT	@account_type_id 	= MIN(account_type_id)
			FROM	#amactval
			WHERE	co_trx_id			= @co_trx_id
			AND		account_type_id 	> @account_type_id
			
		
		END
		
		
		IF @ib_flag_changed = 1 
			UPDATE #gltrx SET interbranch_flag = 1 WHERE journal_ctrl_num = @journal_ctrl_num
		
		
		EXEC @result = gltrxvfy_sp 
				 		@journal_ctrl_num,
						@debug_level 

	 	IF @result <> 0
			RETURN @result

	END

	SELECT	@co_trx_id		= MIN(co_trx_id)
	FROM	#amacthdr
	WHERE	co_trx_id		> @co_trx_id
	AND 	sum_val			= 0



END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amctfact.sp" + ", line " + STR( 251, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCreateTrxsForActivities_sp] TO [public]
GO
