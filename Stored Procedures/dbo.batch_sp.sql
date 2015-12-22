SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\batch.SPv - e7.2.2 : 1.33
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[batch_sp] @Posted_Flag int, 
				@Batch_Date int, 
				@Batch_Time int, 
				@User_Name char(16), 
				@BatchProcKey smallint, 
				@BatchUserId smallint, 
				@BatchOriginFlag smallint
AS

DECLARE @LastBatchCode char(16), 
	@BatchCode char(16), 
	@TotalTrx float,
	@ErrorNum int, 
	@TotalTrxDone float, 
	@ErrorBase int, 
	@IVTRX smallint, 
	@BatchPostFlag smallint, 
	@GLTRX smallint, 
	@GLTRX_2 smallint,
	@GLREALL smallint, 
	@GLRECUR smallint, 
	@IVTRF smallint, 
	@BatchType smallint, 
	@GLModule smallint, 
	@PercDone float,
	@APVOUCH smallint, 
	@APADD smallint, 
	@APDBMEM smallint, 
	@APPYT smallint, 
	@CMMANTRX smallint, 
	@result int,
	@severity int,
	@year smallint, 
	@date smallint, 
	@month smallint,
	@err_mess char(255), 
	@tran_started tinyint,
	@E_INVALID_BATCH_TP int,
	@client_id varchar(20),
	@sav_error int,
	@sav_rowcount int,
	@AP_POSTING tinyint,
	@CM_POSTING tinyint,
	@IV_POSTING tinyint,
	@GL_POSTING tinyint,
	@retval int

SELECT @E_INVALID_BATCH_TP = e_code
FROM glerrdef
WHERE e_sdesc = "E_INVALID_BATCH_TP"

SELECT @ErrorBase = 30000,
	@GLTRX = 6010,
	@GLTRX_2 = 6012, 
	@GLREALL = 6020,
	@GLRECUR = 6030,
	@IVTRX = 5010,
	@IVTRF = 5020,
	@GLModule = 6000,
	@APVOUCH = 4010,
	@APADD = 4020,
	@APDBMEM = 4030,
	@APPYT = 4040,
	@CMMANTRX = 7010



SELECT @TotalTrx = NULL, 
	@tran_started = 0

SELECT @TotalTrx = COUNT( * )
FROM batchctl
WHERE posted_flag = @Posted_Flag
 AND selected_flag = 1
 AND selected_user_id = @BatchUserId

IF (( @TotalTrx IS NULL ) OR ( @TotalTrx !> 0.0 ))
BEGIN
	EXEC status_sp "BATCH", @BatchProcKey, @BatchUserId, 
		"No valid transactions to post!", 100, @BatchOriginFlag, 0
	RETURN 0
END


EXEC status_sp "BATCH", @BatchProcKey, @BatchUserId, "Processing ...", 0,
		@BatchOriginFlag, 0



SELECT @TotalTrxDone = 0.0,
	@LastBatchCode = "X",
	@BatchCode = " "


EXEC appdtjul_sp @year OUTPUT, @month OUTPUT, @date OUTPUT, @Batch_Date

WHILE ( @LastBatchCode != @BatchCode )
BEGIN
	
	SELECT @LastBatchCode = @BatchCode,
		@BatchCode = NULL,
		@result = 0,
		@retval = 0 

	SET ROWCOUNT 1

	SELECT @BatchCode = batch_ctrl_num,
		@BatchType = batch_type
	FROM batchctl
	WHERE posted_flag = @Posted_Flag
	 AND selected_flag = 1
	 AND selected_user_id = @BatchUserId
	 AND batch_ctrl_num > @LastBatchCode
	ORDER BY batch_ctrl_num 

	SELECT @AP_POSTING = 0, 
		@CM_POSTING = 0, 
		@IV_POSTING = 0,
		@GL_POSTING = 0

	IF ((@BatchType = @APVOUCH) OR (@BatchType = @APADD) OR
		 (@BatchType = @APDBMEM) OR (@BatchType = @APPYT))
		SELECT @AP_POSTING = 1
	ELSE
	IF (@BatchType = @CMMANTRX)
		 SELECT @CM_POSTING = 1
	ELSE
	IF ((@BatchType = @IVTRX) OR (@BatchType = @IVTRF) )
		SELECT @IV_POSTING = 1
	ELSE
	IF ( @BatchType = @GLTRX OR @BatchType = @GLTRX_2 ) 
	BEGIN
		SELECT @GL_POSTING = 1

		
		IF EXISTS (SELECT name FROM syscolumns
			WHERE name = 'company_code' 
			AND id = OBJECT_ID('gltrx') )
		 SELECT @BatchType = @GLTRX_2
	END
	ELSE
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT @tran_started = 0
		END

		
		EXEC batchrev_sp @Posted_Flag, @BatchUserId


		EXEC status_sp "BATCH", @BatchProcKey, @BatchUserId, 
		"Invalid Batch Type", 100, @BatchOriginFlag, 1

		RETURN 0
	END

	
	IF (( @@ROWCOUNT = 0 ) OR ( @BatchCode IS NULL ))
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			COMMIT TRAN
			SELECT @tran_started = 0
		END

		SET ROWCOUNT 0
		EXEC status_sp "BATCH", @BatchProcKey, @BatchUserId, 
			"Posting Completed", 100, @BatchOriginFlag, 0

		
		IF ( @BatchType = @GLTRX_2 )
			EXEC glsetpst_sp 

		RETURN 0
	END

	SET ROWCOUNT 0

	
	IF ( @BatchType != @GLTRX_2 )
	BEGIN
		
		IF ( @@trancount = 0 )
		BEGIN
			BEGIN TRAN
			SELECT @tran_started = 1
		END

		UPDATE batchctl
		SET posted_flag = 1,
			posted_user = @User_Name,
			date_posted = @Batch_Date,
			time_posted = @Batch_Time
		WHERE batch_ctrl_num = @BatchCode 
		 AND posted_flag = @Posted_Flag

		SELECT @sav_error = @@ERROR, @sav_rowcount = @@ROWCOUNT

		IF (@sav_error != 0 )
		BEGIN
			IF ( @tran_started = 1 )
			BEGIN
				ROLLBACK TRAN
				SELECT @tran_started = 0
			END
		
			
			EXEC batchrev_sp @Posted_Flag, @BatchUserId

			EXEC status_sp "BATCH", @BatchProcKey, @BatchUserId, 
			"Cannot update Batch Control!", 100, @BatchOriginFlag, 1

			RETURN 0
		END

		
		IF ( @sav_rowcount = 0 )
		BEGIN
			IF ( @tran_started = 1 )
			BEGIN
				COMMIT TRAN
				SELECT @tran_started = 0
			END

			CONTINUE
		END
	END

	
	IF @CM_POSTING = 1
	BEGIN
		EXEC @retval=batchcm_sp @Batch_Date,@BatchProcKey,@BatchUserId, 
		@BatchOriginFlag, @BatchCode, @BatchType, @client_id OUTPUT

		 IF (@retval != 0 )

			BEGIN
				IF ( @tran_started = 1 )
				BEGIN
					ROLLBACK TRAN
					SELECT @tran_started = 0
				END

				
				EXEC batchrev_sp @Posted_Flag, @BatchUserId

				IF @retval > 0 
				
				BEGIN
					SELECT @err_mess = e_ldesc
					FROM glerrdef
					WHERE e_code = @retval
					IF @@ROWCOUNT != 1
					 SELECT @err_mess = 
					 "Invalid error code returned!
						Cannot post batch."
				END
				ELSE
					SELECT @err_mess = 
					 "Cannot preset posted flags!"
				
				EXEC @severity = glputerr_sp 
				@client_id, @BatchUserId, @retval, "BATCH.SP", 
				NULL,@BatchCode, NULL, @BatchType, NULL

				EXEC status_sp "BATCH", @BatchProcKey, 
				 @BatchUserId, @err_mess, 
				 100, @BatchOriginFlag, 1
				RETURN @severity
			END
	END 

	

	ELSE IF @IV_POSTING = 1
	BEGIN
					
		EXEC @retval=batchiv_sp @Batch_Date,@BatchProcKey,@BatchUserId, 
		@BatchOriginFlag, @BatchCode, @BatchType, @client_id OUTPUT
		IF (@retval != 0 )
			BEGIN
				IF ( @tran_started = 1 )
				BEGIN
					ROLLBACK TRAN
					SELECT @tran_started = 0
				END

				
				EXEC batchrev_sp @Posted_Flag, @BatchUserId

				IF @retval > 0 
				
				BEGIN
					SELECT @err_mess = e_ldesc
					FROM glerrdef
					WHERE e_code = @retval
					IF @@ROWCOUNT != 1
						SELECT @err_mess = 
						"Invalid error code returned!
						Cannot post batch."
				END
				ELSE
					SELECT @err_mess = 
					 "Cannot preset posted flags!"

				EXEC @severity = glputerr_sp 
				@client_id, @BatchUserId, @retval, "BATCHIV.SP", 
				NULL, @BatchCode, NULL, @BatchType, NULL

				EXEC status_sp "BATCH", @BatchProcKey, 
				 @BatchUserId, @err_mess, 
				 100, @BatchOriginFlag, 1
				RETURN @severity
			END

	END

	
	ELSE IF @GL_POSTING = 1
	BEGIN
	 
	 IF ( @BatchType = @GLTRX OR @BatchType = @GLTRX_2 )
	 BEGIN
		IF EXISTS ( SELECT ( batch_code ) 
			 FROM gltrx WHERE batch_code = @BatchCode )
		BEGIN
			UPDATE gltrx
			SET posted_flag = (SELECT MAX( posted_flag ) + 2
						FROM gltrx )
			WHERE batch_code = @BatchCode
			
			IF (@@error != 0 )
				RETURN -1
		 
			SET ROWCOUNT 1

			SELECT @BatchPostFlag = posted_flag
			FROM gltrx 
			WHERE batch_code = @BatchCode

			SET ROWCOUNT 0

			EXEC @result = glstd_sp @BatchPostFlag, 
						@Batch_Date, 
						@GLModule, 
						1, 
						@BatchCode, 
						@BatchProcKey, 
						@BatchUserId,
						0

			
			SELECT @client_id = "POSTTRX",
				@retval = @result
		END
	 END

	 
	 IF ( @retval = 0 AND @BatchType = @GLTRX_2 )
	 BEGIN
		UPDATE batchctl
		SET posted_flag = 1,
			posted_user = @User_Name,
			date_posted = @Batch_Date,
			time_posted = @Batch_Time
		WHERE batch_ctrl_num = @BatchCode 
		 AND posted_flag = @Posted_Flag

		IF (@@ERROR != 0 )
		BEGIN
			EXEC status_sp "BATCH", @BatchProcKey, @BatchUserId, 
			"Cannot update Batch Control!", 100, @BatchOriginFlag, 1

			RETURN 0
		END
	 END
	 
	 ELSE IF (@retval != 0 )
	 BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT @tran_started = 0
		END

		
		IF @retval > 0 
		BEGIN
			SELECT @err_mess = e_ldesc
			FROM glerrdef
			WHERE e_code = @retval

			IF @@ROWCOUNT != 1
				SELECT @err_mess = "Invalid error code returned!
					Cannot post batch."
		END
		ELSE
			SELECT @err_mess = "Cannot preset posted flags!"

		EXEC @severity = glputerr_sp @client_id, @BatchUserId, 
		 @retval, "BATCH.SP", NULL, @BatchCode, NULL, @BatchType, 
		 NULL

		EXEC status_sp "BATCH", @BatchProcKey, @BatchUserId,
		 @err_mess, 100, @BatchOriginFlag, 1

		RETURN @severity
	 END
	END
 

	
	


	ELSE
	BEGIN
		IF ( @tran_started = 1 )
		BEGIN
			ROLLBACK TRAN
			SELECT @tran_started = 0
		END

		
		EXEC batchrev_sp @Posted_Flag, @BatchUserId

		SELECT @client_id = "UNKNOWN"
		EXEC status_sp "BATCH", @BatchProcKey, @BatchUserId, 
			"Invalid Batch Type!", 0, @BatchOriginFlag, 1

		IF ( @AP_POSTING = 1 )
			EXEC @severity = apputerr_sp 
			@client_id,@BatchUserId,@E_INVALID_BATCH_TP,"BATCH.SP", 
			NULL, @BatchCode, NULL, @BatchType, NULL
		ELSE
			EXEC @severity = glputerr_sp 
			@client_id,@BatchUserId,@E_INVALID_BATCH_TP,"BATCH.SP", 
				NULL, @BatchCode, NULL, @BatchType, NULL

		
		IF ( @severity > 2 )
			RETURN @severity
	END

	
	SELECT @TotalTrxDone = @TotalTrxDone + 1, 
		@PercDone = @TotalTrxDone / @TotalTrx * 100

	EXEC status_sp "BATCH", @BatchProcKey, @BatchUserId, "Processing ...", 
			@PercDone, @BatchOriginFlag, 0

	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRAN
		SELECT @tran_started = 0
	END
END

RETURN 0



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[batch_sp] TO [public]
GO
