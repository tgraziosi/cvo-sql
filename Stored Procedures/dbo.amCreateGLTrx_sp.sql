SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateGLTrx_sp]
(
	@process_ctrl_num	smProcessCtrlNum,				
	@batch_code			smBatchCode,					
	@user_id			smUserID,						
	@company_code		smCompanyCode,					
	@trx_type			smTrxType,						
	@debug_level		smDebugLevel 	= 0				
)						
AS 

DECLARE 
	@result						smErrorCode,
	@message					smErrorLongDesc,
	@journal_type 	smJournalType,	 	
	@trx_ctrl_num				smControlNumber,
	@journal_ctrl_num			smControlNumber,
	@trx_description 		smStdDescription, 
	@doc_reference				smDocumentReference,
	@date_entered 	 	smJulianDate,
	@date_applied 	smJulianDate,
	@company_id					smCompanyID,
	@home_currency_code 	smCurrencyCode,
	@gl_trx_type 	smallint,				
	@sequence_id				smCounter,
	@account_id					smSurrogateKey,
	@account_code	 			smAccountCode,
	@account_reference_code	 	smAccountReferenceCode,
	@amount		 				smMoneyZero,
	@curr_precision 			smallint,				
	@rounding_factor 			float,
	@ib_org_id                             	varchar(30),
	@ib_org_id_det                        	varchar(30)
	, @ib_co_trx_id                       	int, 
	@original_org_id                      	varchar(30), 	
	@ib_flag_changed			smallint,	
	@asset_org_id				varchar(30) 	

DECLARE @str	char(255)
DECLARE	@a	float
	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/amgltrx.sp' + ', line ' + STR( 155, 5 ) + ' -- ENTRY: '



select @ib_org_id    ='',@ib_org_id_det=''   
select @ib_flag_changed = 0		

SELECT	@company_id				= company_id,
		@home_currency_code 	= home_currency
		
FROM	glco
WHERE	company_code 			= @company_code



EXEC	@result = amGetCurrencyPrecision_sp
					@curr_precision		OUTPUT,
					@rounding_factor 	OUTPUT

IF @result <> 0
	RETURN @result

IF @debug_level > 3
	SELECT	'Currency Precision = ' + CONVERT(char(20), @curr_precision) 
	 

EXEC @result = glgetjrn_sp 
				@journal_type 		OUTPUT,		
				10000,			
				0								

IF @result <> 0
BEGIN
	EXEC 		amGetErrorMessage_sp 20200, 'tmp/amgltrx.sp', 190, @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20200 @message
	RETURN		20200
END

SELECT @asset_org_id = MIN(isnull(asset_org_id, '')) 	
FROM #amsumval

WHILE @asset_org_id IS NOT NULL		
BEGIN
	
	SELECT	@journal_ctrl_num		= NULL
	
	
	SELECT 
			@trx_ctrl_num	 		= trx_ctrl_num,
			@trx_description 		= trx_description,
			@doc_reference			= doc_reference,
			@date_entered 			= DATEDIFF(dd, '1/1/1980', last_modified_date) + 722815,
			@date_applied 			= DATEDIFF(dd, '1/1/1980', apply_date) + 722815,
			@gl_trx_type			= 10000 + trx_type, 
			@ib_co_trx_id			= co_trx_id 
	FROM 	#amtrxhdr
		
 	IF @debug_level > 3
 	BEGIN
 		
		SELECT	'Trx Ctrl Num    = ' + @trx_ctrl_num 
 		SELECT	'Trx Description = ' + ISNULL(@trx_description , ' ')
 		SELECT	'GL Trx Type     = ' + CONVERT(char(20), @gl_trx_type) 
 	END

	SELECT @ib_org_id = @asset_org_id	
	IF @ib_org_id is null 			
		SELECT	@ib_org_id = org_id							
		FROM	amOrganization_vw						
		WHERE	outline_num = '1'						
	
	SELECT @ib_org_id = ISNULL(@ib_org_id,'')                                   
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

	
	UPDATE 	#amtrxhdr
	SET 	journal_ctrl_num 	= @journal_ctrl_num
	FROM	#amtrxhdr

	SELECT @result = @@error
 	IF @result <> 0
		RETURN @result

	SELECT	@account_id = MIN(account_id)
	FROM	#amsumval
	WHERE asset_org_id = @asset_org_id	
			
	WHILE @account_id IS NOT NULL
	BEGIN

		SELECT	@sequence_id	= 0
		
		SELECT 	@account_code 			= account_code,
				@account_reference_code = account_reference_code,
				@amount 				= (SIGN(amount) * ROUND(ABS(amount) + 0.0000001, @curr_precision))
		FROM 	#amsumval 
		WHERE 	account_id 				= @account_id
		AND 	asset_org_id = @asset_org_id	

 
 		SELECT @ib_org_id_det = ISNULL(dbo.IBOrgbyAcct_fn(@account_code),'')  
		
		IF @original_org_id <> @ib_org_id_det 	
			SELECT @ib_flag_changed = 1	
		                
		IF @debug_level > 3
		BEGIN
                       	SELECT @a = 0 , @str = ''

		            
			SELECT	'Account code : ' + @account_code  
                        SELECT  'Account Reference Code : '+ ISNULL(@account_reference_code, ' ')
                        SELECT  'Org_id : ' +  @ib_org_id_det 
                      
                        SELECT	@a = CONVERT(float, @amount)
			SELECT	@str = '$' + LTRIM(CONVERT(char(255), ISNULL(@a,0)))
                        




                       SELECT   'Amount : ' + @str

 		END
 		
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
							@debug	= @debug_level,
							@ib_org_id = @ib_org_id_det        
							
									
							
							
							
							
 		IF @result <> 0
			RETURN @result

		SELECT	@account_id = MIN(account_id)
		FROM	#amsumval
		WHERE	account_id 	> @account_id
		AND asset_org_id = @asset_org_id	
			
	END

	
	IF @ib_flag_changed = 1 
		UPDATE #gltrx SET interbranch_flag = 1 WHERE journal_ctrl_num = @journal_ctrl_num
	

	EXEC @result = gltrxvfy_sp 
			 		@journal_ctrl_num,
					@debug_level 

 	IF @result <> 0
		RETURN @result

	SELECT @asset_org_id = MIN(isnull(asset_org_id, '')) 
	FROM #amsumval
	WHERE asset_org_id > @asset_org_id	

END


EXEC @result = amCreateTrxsForActivities_sp
					@process_ctrl_num,
					@batch_code,
					@user_id,
					@company_code,
					@journal_type,
					@home_currency_code,
					@curr_precision,
					@debug_level
 
IF @result <> 0
	RETURN @result



EXEC @result = amCreateTrxsForSumActivitis_sp
					@process_ctrl_num,
					@batch_code,
					@user_id,
					@company_code,
					@journal_type,
					@home_currency_code,
					@curr_precision,
					@debug_level
 
IF @result <> 0
	RETURN @result



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/amgltrx.sp' + ', line ' + STR( 380, 5 ) + ' -- EXIT: '

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCreateGLTrx_sp] TO [public]
GO
