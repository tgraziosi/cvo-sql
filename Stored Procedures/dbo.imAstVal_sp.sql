SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imAstVal_sp] 
( 
	@action						smallint,
	@company_id					smallint,				
	@asset_ctrl_num				char(16),					
	@asset_description			varchar(40) 	= "",	
	@is_new						int				= 0,	
	@original_cost				float 			= 0,	
	@acquisition_date			char(8) 		= NULL,	
	@placed_in_service_date		char(8) 		= NULL, 
	@original_in_service_date	char(8) 		= NULL,	
	@disposition_date			char(8) 		= NULL,	
	@orig_quantity				int 			= 1,	
	@category_code				char(8)		 	= NULL,	
	@status_code				char(8)	 		= NULL,	
	@asset_type_code			char(8)	 		= NULL,	
	@employee_code				char(9)	 		= NULL,	
	@location_code				char(8)	 		= NULL,	
	@business_usage				float 			= 100,	
	@personal_usage				float 			= 0,	
	@investment_usage			float 			= 0,	
	@account_reference_code		varchar(32) 	= "",	
	@tag						varchar(32) 	= "",	
	@is_pledged					int 			= 0,	


	@lease_type					int 			= 0,	
	@is_property				int 			= 0,	


	@last_modified_date			char(8) 		= NULL,	
	@modified_by				int 			= 1,	
	@policy_number				varchar(40) 	= "",	
	@stop_on_error				tinyint			= 1,	
	@is_valid					tinyint 		OUTPUT,	




	@debug_level				smallint		= 0		
	,@org_id					varchar(30) = NULL
)
AS 

DECLARE
	@result						int,					
	@does_exist					tinyint,				
	@message					varchar(255),			
	@param1						varchar(255),			
	@param2						varchar(255),			
	@param3						varchar(255),			
	@dates_valid				tinyint,				
	@activity_state				tinyint,				
	@is_imported				tinyint,				
	@disposition_date_dt		datetime,				
	@placed_in_service_date_dt	datetime,				
	@acquisition_date_dt		datetime,				
	@jul_date					int,					
	@jul_cur_prd_end			int,					
	@co_asset_id				int						
	,@org_flag				int
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imastval.cpp" + ", line " + STR( 159, 5 ) + " -- ENTRY: "

SELECT 	@is_valid 		= 1,
		@co_asset_id 	= 0

IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)

IF @disposition_date IS NOT NULL
	SELECT	@disposition_date_dt 		= CONVERT(datetime, @disposition_date)
ELSE
	SELECT	@disposition_date_dt 		= NULL

IF @acquisition_date IS NOT NULL
	SELECT	@acquisition_date_dt 		= CONVERT(datetime, @acquisition_date)
ELSE
	SELECT	@acquisition_date_dt 		= NULL

IF @placed_in_service_date IS NOT NULL
	SELECT	@placed_in_service_date_dt 	= CONVERT(datetime, @placed_in_service_date)
ELSE
	SELECT	@placed_in_service_date_dt 	= NULL
	
EXEC @result = amassetExists_sp
					@company_id, 
					@asset_ctrl_num, 
					@does_exist 	OUTPUT
IF @result <> 0
	RETURN @result




IF @action = 1 OR @action = 2
BEGIN
	IF @does_exist = 0
	BEGIN
		EXEC 		amGetErrorMessage_sp 21000, "imastval.cpp", 196, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21000 @message 
		SELECT 		@is_valid = 0
		
		IF @stop_on_error = 1
			RETURN 0	
	END
	ELSE
	BEGIN
		


		SELECT 	@activity_state = activity_state,
				@is_imported	= is_imported,
				@co_asset_id	= co_asset_id
		FROM	amasset
		WHERE	company_id		= @company_id
		AND		asset_ctrl_num	= @asset_ctrl_num
		
		IF 	@activity_state <> 100 
		BEGIN
			EXEC 		amGetErrorMessage_sp 21019, "imastval.cpp", 217, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21019 @message 
			SELECT 		@is_valid = 0
			
			IF @stop_on_error = 1
				RETURN 0	
		END
	
		IF @is_imported = 0
		BEGIN
			EXEC 		amGetErrorMessage_sp 21018, "imastval.cpp", 227, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21018 @message 
			SELECT 		@is_valid = 0
			
			IF @stop_on_error = 1
				RETURN 0	
		END
	END
END




IF @does_exist = 1 AND @action = 0
BEGIN
	EXEC 		amGetErrorMessage_sp 	21001, "imastval.cpp", 242, @asset_ctrl_num, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	21001 @message 
	SELECT 		@is_valid = 0
	RETURN 		0				
END




IF @action = 2 OR @action = 0
BEGIN
	


	IF @category_code IS NULL
	BEGIN
		EXEC 		amGetErrorMessage_sp 21008, "imastval.cpp", 258, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21008 @message 
		SELECT 		@is_valid = 0
		
		IF @stop_on_error = 1
			RETURN 0	
	END
	ELSE
	BEGIN
		EXEC @result = amcat_vwExists_sp
							@category_code, 
							@does_exist 	OUTPUT
		IF @result <> 0
			RETURN @result

		IF @does_exist = 0
		BEGIN
			EXEC 		amGetErrorMessage_sp 21002, "imastval.cpp", 275, @asset_ctrl_num, @category_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21002 @message 
			SELECT 		@is_valid = 0
		
			IF @stop_on_error = 1
				RETURN 0	
		END
		ELSE
		BEGIN
			



			IF 	@acquisition_date_dt IS NOT NULL
			AND	NOT EXISTS (SELECT 	book_code
					  	 	FROM	amcatbk
							WHERE	category_code	= @category_code
							AND		effective_date	<= @acquisition_date_dt)
			BEGIN
				EXEC 		amGetErrorMessage_sp 21028, "imastval.cpp", 294, @asset_ctrl_num, @category_code, @acquisition_date_dt, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	21028 @message 
				SELECT 		@is_valid = 0
			
				IF @stop_on_error = 1
					RETURN 0	
			END
		END
	END

	


	IF @status_code <> NULL
	BEGIN
		EXEC @result = amstatusExists_sp
							@status_code, 
							@does_exist 	OUTPUT
		IF @result <> 0
			RETURN @result

		IF @does_exist = 0
		BEGIN
			EXEC 		amGetErrorMessage_sp 21003, "imastval.cpp", 317, @asset_ctrl_num, @status_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21003 @message 
			SELECT 		@is_valid = 0
		
			IF @stop_on_error = 1
				RETURN 0	
		END
	END
	
	


	IF @location_code <> NULL
	BEGIN
		EXEC @result = amlocExists_sp
							@location_code, 
							@does_exist 	OUTPUT
		IF @result <> 0
			RETURN @result

		IF @does_exist = 0
		BEGIN
			EXEC 		amGetErrorMessage_sp 21004, "imastval.cpp", 339, @asset_ctrl_num, @location_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21004 @message 
			SELECT 		@is_valid = 0
		
			IF @stop_on_error = 1
				RETURN 0	
		END
	END

	


	IF @employee_code <> NULL
	BEGIN
		EXEC @result = amempExists_sp
							@employee_code, 
							@does_exist 	OUTPUT
		IF @result <> 0
			RETURN @result

		IF @does_exist = 0
		BEGIN
			EXEC 		amGetErrorMessage_sp 21005, "imastval.cpp", 361, @asset_ctrl_num, @employee_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21005 @message 
			SELECT 		@is_valid = 0
		
			IF @stop_on_error = 1
				RETURN 0	
		END
	END
	
	


	IF @asset_type_code <> NULL
	BEGIN
		EXEC @result = amasttypExists_sp
							@asset_type_code, 
							@does_exist 	OUTPUT
		IF @result <> 0
			RETURN @result

		IF @does_exist = 0
		BEGIN
			EXEC 		amGetErrorMessage_sp 21006, "imastval.cpp", 383, @asset_ctrl_num, @asset_type_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21006 @message 
			SELECT 		@is_valid = 0
		
			IF @stop_on_error = 1
				RETURN 0	
		END
	END
	
	


	IF @account_reference_code <> "" AND @account_reference_code <> NULL
	BEGIN
		EXEC @result = amglrefExists_sp
							@account_reference_code, 
							@does_exist 	OUTPUT
		IF @result <> 0
			RETURN @result

		IF @does_exist = 0
		BEGIN
			EXEC 		amGetErrorMessage_sp 21007, "imastval.cpp", 405, @asset_ctrl_num, @account_reference_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21007 @message 
			SELECT 		@is_valid = 0
	
			IF @stop_on_error = 1
				RETURN 0	
		END
	END

	


	EXEC @result = amValidateAssetDates_sp
							@co_asset_id,				
							@asset_ctrl_num,
							@acquisition_date,
							@placed_in_service_date,
							@dates_valid OUTPUT
	IF @result <> 0
		RETURN @result

	IF @dates_valid = 0
		SELECT 	@is_valid = 0

	


	IF (ABS((@business_usage + @personal_usage + @investment_usage - 100)-(0.0)) > 0.0000001)   
	BEGIN 
		SELECT @param1 = RTRIM(CONVERT(char(255),  @business_usage))
		SELECT @param2 = RTRIM(CONVERT(char(255),  @personal_usage))
		SELECT @param3 = RTRIM(CONVERT(char(255),  @investment_usage))
		
		EXEC	 	amGetErrorMessage_sp 21020, "imastval.cpp", 438, @asset_ctrl_num, @param1, @param2, @param3, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21020 @message 
		SELECT 		@is_valid = 0

		IF @stop_on_error = 1
			RETURN 0	
	END 
	
	


	IF @lease_type NOT IN (1, 2, 3)
	BEGIN
		SELECT @param1 = RTRIM(CONVERT(char(255),  @lease_type))
		
		EXEC	 	amGetErrorMessage_sp 21010, "imastval.cpp", 453, @asset_ctrl_num, @param1, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21010 @message 
		SELECT 		@is_valid = 0	
		
		IF @stop_on_error = 1
			RETURN 0	
	END

	


	IF @is_pledged NOT IN (0, 1)
	BEGIN
		SELECT @param1 = RTRIM(CONVERT(char(255),  @is_pledged))
		
		EXEC	 	amGetErrorMessage_sp 21011, "imastval.cpp", 468, @asset_ctrl_num, @param1, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21011 @message 
		SELECT 		@is_valid = 0	
	
		IF @stop_on_error = 1
			RETURN 0	
	END

	


	IF @is_property NOT IN (0, 1)
	BEGIN
		SELECT @param1 = rtrim(convert(char(255),  @is_property))
		
		EXEC	 	amGetErrorMessage_sp 21012, "imastval.cpp", 483, @asset_ctrl_num, @param1, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21012 @message 
		SELECT 		@is_valid = 0	
	
		IF @stop_on_error = 1
			RETURN 0	
	END

	














	














	


	IF @orig_quantity < 0
	BEGIN
		SELECT @param1 = RTRIM(convert(char(255),  @orig_quantity))
		
		EXEC	 	amGetErrorMessage_sp 21016, "imastval.cpp", 528, @asset_ctrl_num, @param1, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21016 @message 
		SELECT 		@is_valid = 0	
		
		IF @stop_on_error = 1
			RETURN 0	
	END

	


	IF @modified_by <= 0
	BEGIN
		SELECT @param1 = RTRIM(CONVERT(char(255),  @modified_by))
		
		EXEC	 	amGetErrorMessage_sp 21029, "imastval.cpp", 543, @asset_ctrl_num, @param1, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21029 @message 
		SELECT 		@is_valid = 0	
		
		IF @stop_on_error = 1
			RETURN 0	
	END
	
	IF @disposition_date IS NOT NULL
	BEGIN
		


		IF @disposition_date_dt < @acquisition_date_dt
		BEGIN
			EXEC	 	amGetErrorMessage_sp 21021, "imastval.cpp", 558, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21021 @message 
			SELECT 		@is_valid = 0	
			
			IF @stop_on_error = 1
				RETURN 0	
		END
		


		IF 	@placed_in_service_date IS NOT NULL
		AND	@disposition_date_dt < @placed_in_service_date_dt
		BEGIN
			EXEC	 	amGetErrorMessage_sp 21022, "imastval.cpp", 571, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21022 @message 
			SELECT 		@is_valid = 0	
			
			IF @stop_on_error = 1
				RETURN 0	
		END

		


		SELECT @jul_date = DATEDIFF(dd, "1/1/1980", @disposition_date_dt) + 722815

		IF NOT EXISTS(SELECT *
						FROM   glprd 
						WHERE  period_end_date 		>= @jul_date
						AND	   period_start_date 	<= @jul_date) 
		BEGIN
			EXEC	 	amGetErrorMessage_sp 21023, "imastval.cpp", 589, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21023 @message 
			SELECT 		@is_valid = 0
			
			IF @stop_on_error = 1
				RETURN 0	
		END

		


		SELECT	@jul_cur_prd_end = period_end_date
		FROM	glco
		
		IF @jul_date > @jul_cur_prd_end
		BEGIN
			EXEC	 	amGetErrorMessage_sp 21024, "imastval.cpp", 605, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21024 @message 
			SELECT 		@is_valid = 0
			
			IF @stop_on_error = 1
				RETURN 0	
		END

	END

	


	IF 	@is_new = 1
	AND	@disposition_date IS NOT NULL
	BEGIN
		EXEC	 	amGetErrorMessage_sp 21027, "imastval.cpp", 621, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21027 @message 
		SELECT 		@is_valid = 0
			
		IF @stop_on_error = 1
			RETURN 0	
	END


	




	




	SELECT @org_flag = ib_flag FROM glco
	IF @org_flag = 0 AND @org_id IS NULL
	BEGIN
		



		IF NOT EXISTS ( SELECT 	org_id 
				FROM 	amOrganization_vw
				WHERE   outline_num = '1'
				AND     active_flag = 1)
		BEGIN

			EXEC	 	amGetErrorMessage_sp 21032, "imastval.cpp", 653, @org_id, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21032 @message 
			SELECT 		@is_valid = 0
				
			IF @stop_on_error = 1
				RETURN 0	
		END

		



		SELECT @org_id = org_id 
		from amOrganization_vw
		where outline_num = '1'
	END



	




	IF 	@org_id IS NULL
	BEGIN
		EXEC	 	amGetErrorMessage_sp 21030, "imastval.cpp", 679, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	21030 @message 
		SELECT 		@is_valid = 0
			
		IF @stop_on_error = 1
			RETURN 0
	END
	ELSE
	BEGIN
		



		IF NOT EXISTS ( SELECT 	org_id 
				FROM 	amOrganization_vw
				WHERE   org_id = @org_id
				AND     active_flag = 1)
		BEGIN
			EXEC	 	amGetErrorMessage_sp 21031, "imastval.cpp", 697, @org_id, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	21031 @message 
			SELECT 		@is_valid = 0
				
			IF @stop_on_error = 1
				RETURN 0	
		END
	END

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imastval.cpp" + ", line " + STR( 708, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imAstVal_sp] TO [public]
GO
