SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCreateAllAccounts_sp] 
( 	
	@company_id 		smCompanyID, 					
	@apply_date			smApplyDate,	 			 	
	@trx_type			smTrxType	= 50,	
	@start_book			smBookCode	= NULL,																		
	@end_book			smBookCode	= NULL,				
	@show_acct_msgs		smLogical	= 1,
	@start_org_id           smOrgId,
	@end_org_id             smOrgId,
	@debug_level		smDebugLevel= 0,				
	@perf_level			smPerfLevel	= 0					
) 
AS 



DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()


DECLARE 
	@result					smErrorCode,
	@co_asset_id			smSurrogateKey,			
	@co_trx_id				smSurrogateKey,			
	@asset_ctrl_num			smControlNumber,		
	@account_type_id		smAccountTypeID,		
	@error_code				smErrorCode,			
	@message				smErrorLongDesc,		
	@account_reference_code	smAccountReferenceCode,		
	@account_code			smAccountCode,			
	@account_type_desc		smStdDescription,		
	@jul_apply_date			smJulianDate,			
	@apply_date_str			char(20),				
	@home_currency_code		smCurrencyCode

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcralac.sp" + ", line " + STR( 103, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "tmp/amcralac.sp", 104, "Enter amCreateAllAccounts_sp", @PERF_time_last OUTPUT


IF @trx_type = 100
BEGIN
	
	EXEC @result = amLoadAllAddAccounts_sp
						@company_id,
						@start_org_id,
						@end_org_id,
						@debug_level

	IF @result <> 0
		RETURN 	@result
END
ELSE
BEGIN
	EXEC @result = amLoadAllAccounts_sp
						@company_id,
						@apply_date,
						@trx_type,
						@start_book,
						@end_book,
						@start_org_id,
						@end_org_id,
						@debug_level,
						@perf_level

	IF @result <> 0
		RETURN 	@result
END




CREATE TABLE #amaccerr
(	
	error_code					int,			
	error_message				varchar(255)	
)


IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "tmp/amcralac.sp", 142, "Loaded all accounts", @PERF_time_last OUTPUT

/* rev */
update #amaccts set org_id = a.org_id 
 from  #amaccts , amasset a 
 where #amaccts.co_asset_id = a.co_asset_id
/* rev */

EXEC @result = amCreateAccounts_sp
				 @company_id,
				 @debug_level,
				 @perf_level
IF @result <> 0
BEGIN
	DROP TABLE #amaccerr
	RETURN 	@result
END




IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "tmp/amcralac.sp", 157, "Dynamically created all accounts", @PERF_time_last OUTPUT

IF @trx_type != 100
BEGIN
	EXEC @result = amLoadAPInterfaceAccounts_sp
						@company_id,
						@apply_date,
						@trx_type,
						@start_book,
						@end_book,
						@debug_level

	IF @result <> 0
		RETURN 	@result
END

IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "tmp/amcralac.sp", 173, "Loaded AP accounts", @PERF_time_last OUTPUT

 
EXEC @result = amGetCurrencyCode_sp 
					@company_id,
					@home_currency_code OUTPUT 

IF @result <> 0
	RETURN @result


EXEC @result = amValidateAllAccounts_sp 
				 	@home_currency_code,
				 	@debug_level
					WITH RECOMPILE
IF @result <> 0
BEGIN
	DROP TABLE #amaccerr
	RETURN @result
END

IF ( @perf_level >= 2 ) EXEC perf_sp "Create Accounts", "tmp/amcralac.sp", 199, "Validated all accounts", @PERF_time_last OUTPUT


DROP TABLE #amaccerr


IF (@show_acct_msgs = 1)
BEGIN
	
	SELECT	@co_asset_id	= MIN(co_asset_id)
	FROM	#amaccts
	WHERE	error_code		!= 0

	WHILE @co_asset_id	IS NOT NULL
	BEGIN
		IF @debug_level >= 5
			SELECT	co_asset_id = @co_asset_id

		SELECT	@jul_apply_date		= MIN(jul_apply_date)
		FROM	#amaccts
		WHERE	co_asset_id			= @co_asset_id
		AND		error_code			!= 0

		WHILE @jul_apply_date	IS NOT NULL
		BEGIN
			IF @debug_level >= 5
				SELECT	jul_apply_date = @jul_apply_date

			SELECT	@apply_date_str	= CONVERT(char(20), DATEADD(dd, @jul_apply_date - 722815, "1/1/1980"))

			
			SELECT	@co_trx_id			= MIN(co_trx_id)
			FROM	#amaccts
			WHERE	co_asset_id			= @co_asset_id
			AND		jul_apply_date		= @jul_apply_date
			AND		error_code			!= 0

			WHILE @co_trx_id	IS NOT NULL
			BEGIN
				IF @debug_level >= 5
					SELECT	co_trx_id = @co_trx_id

				SELECT	@account_type_id	= MIN(account_type_id)
				FROM	#amaccts
				WHERE	co_asset_id			= @co_asset_id
				AND		jul_apply_date		= @jul_apply_date
				AND		co_trx_id			= @co_trx_id
				AND		error_code			!= 0

				WHILE @account_type_id	IS NOT NULL
				BEGIN
					IF @debug_level >= 5
						SELECT	account_type_id = @account_type_id

					SELECT	@asset_ctrl_num			= a.asset_ctrl_num,
							@account_code			= tmp.new_account_code,
							@account_reference_code	= tmp.account_reference_code,
							@error_code				= tmp.error_code 
					FROM	#amaccts 	tmp,
							amasset		a,
							amOrganization_vw o
					WHERE	tmp.co_asset_id			= @co_asset_id
					AND		tmp.jul_apply_date		= @jul_apply_date
					AND		tmp.co_trx_id			= @co_trx_id
					AND		tmp.account_type_id		= @account_type_id
					AND		tmp.co_asset_id			= a.co_asset_id
					AND		tmp.co_asset_id			= @co_asset_id
					AND             a.org_id                        = o.org_id
					AND             a.org_id   BETWEEN @start_org_id AND @end_org_id              

					
					SELECT	@account_type_desc 	= account_type_description
					FROM	amacctyp
					WHERE	account_type		= @account_type_id

					
					IF @error_code = 20140
					BEGIN
						SELECT	@error_code = 20150 
						EXEC 	amGetErrorMessage_sp 20150, "tmp/amcralac.sp", 292, @asset_ctrl_num, @account_type_desc, @account_code, @error_message = @message OUT 
					END

					ELSE IF @error_code = 20141
					BEGIN
						SELECT	@error_code = 20151 
						EXEC 	amGetErrorMessage_sp 20151, "tmp/amcralac.sp", 298, @asset_ctrl_num, @account_type_desc, @account_code, @error_message = @message OUT 
					END
				
					ELSE IF @error_code = 20142
					BEGIN
						SELECT	@error_code = 20152 
						EXEC 	amGetErrorMessage_sp 20152, "tmp/amcralac.sp", 304, @asset_ctrl_num, @account_type_desc, @account_code, @apply_date_str, @error_message = @message OUT 
					END
					
					ELSE IF @error_code = 20143
					BEGIN
						SELECT	@error_code = 20153 
						EXEC 	amGetErrorMessage_sp 20153, "tmp/amcralac.sp", 310, @asset_ctrl_num, @account_type_desc, @account_reference_code, @account_code, @error_message = @message OUT 
					END
					
					ELSE IF @error_code = 20144
					BEGIN
						SELECT	@error_code = 20154 
						EXEC 	amGetErrorMessage_sp 20154, "tmp/amcralac.sp", 316, @asset_ctrl_num, @account_type_desc, @account_code, @error_message = @message OUT 
					END
					
					ELSE IF @error_code = 20145
					BEGIN
						SELECT	@error_code = 20155 
						EXEC 	amGetErrorMessage_sp 20155, "tmp/amcralac.sp", 322, @asset_ctrl_num, @account_type_desc, @account_code, @account_reference_code, @error_message = @message OUT 
					END

					ELSE IF @error_code = 20146
					BEGIN
						SELECT	@error_code = 20156 
						EXEC 	amGetErrorMessage_sp 20156, "tmp/amcralac.sp", 328, @asset_ctrl_num, @account_type_desc, @account_reference_code, @error_message = @message OUT 
					END
					
					ELSE IF @error_code = 20147
					BEGIN
						SELECT	@error_code = 20157 
						EXEC 	amGetErrorMessage_sp 20157, "tmp/amcralac.sp", 334, @asset_ctrl_num, @account_type_desc, @account_reference_code, @error_message = @message OUT 
					END
					
					ELSE IF @error_code = 20148
					BEGIN
						SELECT	@error_code = 20158 
						EXEC 	amGetErrorMessage_sp 20158, "tmp/amcralac.sp", 340, @asset_ctrl_num, @account_type_desc, @account_reference_code, @account_code, @error_message = @message OUT 
					END
					
					ELSE IF @error_code = 20149
					BEGIN
						SELECT	@error_code = 20159 
						EXEC 	amGetErrorMessage_sp 20159, "tmp/amcralac.sp", 346, @asset_ctrl_num, @account_type_desc, @account_code, @error_message = @message OUT 
					END
	
					
					IF @message IS NOT NULL RAISERROR 	@error_code @message 
				
					
					SELECT	@account_type_id	= MIN(account_type_id)
					FROM	#amaccts
					WHERE	co_asset_id			= @co_asset_id
					AND		jul_apply_date		= @jul_apply_date
					AND		co_trx_id			= @co_trx_id
					AND		account_type_id		> @account_type_id
					AND		error_code			!= 0

				END

				
				SELECT	@co_trx_id			= MIN(co_trx_id)
				FROM	#amaccts
				WHERE	co_asset_id			= @co_asset_id
				AND		jul_apply_date		= @jul_apply_date
				AND		co_trx_id			> @co_trx_id
				AND		error_code			!= 0

			END

			
			SELECT	@jul_apply_date		= MIN(jul_apply_date)
			FROM	#amaccts
			WHERE	co_asset_id			= @co_asset_id
			AND		jul_apply_date		> @jul_apply_date
			AND		error_code			!= 0

		END	
		
		
		SELECT	@co_asset_id		= MIN(co_asset_id)
		FROM	#amaccts
		WHERE	co_asset_id			> @co_asset_id
		AND		error_code			!= 0

	END	

END	


EXEC @result = amUpdateWithSuspenseAccts_sp
					@company_id,
					@debug_level

IF @result <> 0
	RETURN 	@result

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcralac.sp" + ", line " + STR( 413, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "tmp/amcralac.sp", 414, "Exit amCreateAllAccounts_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCreateAllAccounts_sp] TO [public]
GO
