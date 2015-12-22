SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE  PROCEDURE [dbo].[gltrxhdr_sp]
	@module_id              smallint,
	@journal_type           varchar(8),
	@journal_ctrl_num       varchar(16) OUTPUT,
	@journal_description    varchar(30),    
	@date_entered           int,
	@date_applied           int,
	@recurring_flag         smallint,
	@repeating_flag         smallint,
	@reversing_flag         smallint,
	@source_batch_code      varchar(16),
	@batch_code             varchar(16) OUTPUT,
	@type_flag              smallint,
	@intercompany_flag      smallint,
	@company_code           varchar(8),
	@home_cur_code          varchar(8),
	@document_1             varchar(16),
	@trx_type               smallint,
	@user_id                smallint,
	@hold_flag              smallint,
	@error_flag             int = 0 OUTPUT,
	@org_id					varchar(30),			
	@interbranch_flag		smallint = 0			
AS

DECLARE
	@batch_proc_flag        smallint,
	@float_buff             float,          
	@int_buff               smallint,       
	@jcc_len                smallint,       
	@char_buff              varchar(16),    
	@user_name              varchar(30),    
	@next_flag              smallint,
	@result                 int,
	@client_id              varchar(20),
	@posted_flag            smallint,
	@process_host_id        varchar(16),
	@process_ctrl_num       varchar(16),
	@oper_cur_code          varchar(8),
	@desc                   varchar(40)

SELECT  @client_id = "POSTTRX"





IF ( RTRIM(@company_code) = "" ) OR ( RTRIM(@company_code) IS NULL )
	SELECT  @company_code = company_code
	FROM    glco
	
IF EXISTS(      SELECT  *
		FROM    #pcontrol )
BEGIN
	SELECT  @process_ctrl_num = process_ctrl_num
	FROM    #pcontrol
END

ELSE
BEGIN
	EXEC    glgetstr_sp     7,
				@desc OUTPUT
				
	EXEC    @result = pctrladd_sp   @process_ctrl_num OUTPUT,
					@desc,
					@user_id,
					@module_id,
					@company_code,
					0
	IF ( @result != 0 )                               
	BEGIN   
		SELECT  @error_flag = @result
		return @result
	END

	EXEC    @result = pctrlupd_sp   @process_ctrl_num,
					4
	IF ( @result != 0 )
	BEGIN
		SELECT  @error_flag = @result
		return @result
	END
		
	INSERT  #pcontrol (
		process_ctrl_num,
		process_parent_app,
		process_parent_company,
		process_description,
		process_user_id,
		process_server_id,
		process_host_id,
		process_kpid,
		process_start_date,
		process_end_date,
		process_state )
	SELECT  process_ctrl_num,
		process_parent_app,
		process_parent_company,
		process_description,
		process_user_id,
		process_server_id,
		process_host_id,
		process_kpid,
		process_start_date,
		process_end_date,
		process_state
	FROM    pcontrol_vw
	WHERE   process_ctrl_num = @process_ctrl_num
	
	IF ( @@error != 0 )
	BEGIN
		SELECT  @error_flag = 1039
		return  @error_flag
	END
END

SELECT  @posted_flag = -1




IF NOT EXISTS (SELECT * FROM glappid
			WHERE app_id = @module_id)
BEGIN
	EXEC @result =  glputerr_sp     @client_id,
					@user_id,
					1003,
					"GLTRXHDR.SP",
					NULL,           
					"Invalid #",    
					NULL,           
					@module_id,     
					NULL            
	SELECT @error_flag = 1003
	RETURN @error_flag
END


IF (RTRIM(@journal_type) = "") OR (RTRIM(@journal_type) IS NULL )
	SELECT @journal_type = journal_type
	FROM glappid
	WHERE app_id = @module_id


IF NOT EXISTS (SELECT * FROM gljtype
			WHERE journal_type = @journal_type)
BEGIN
	SELECT @journal_type = 'GJ'
END


IF @journal_description IS NULL
BEGIN
	SELECT  @journal_description = " "
END


IF @date_entered !> 0
BEGIN
	EXEC @result =  glputerr_sp     @client_id, 
					@user_id,
					1022,
					"GLTRXHDR.SP",
					NULL,           
					NULL,           
					NULL,           
					@date_entered,  
					NULL            
	SELECT @error_flag = 1022
	RETURN @error_flag
END


IF @date_applied !> 0
BEGIN
	EXEC @result =  glputerr_sp     @client_id, 
					@user_id,
					1023,
					"GLTRXHDR.SP",
					NULL,           
					NULL,           
					NULL,           
					@date_applied,  
					NULL            
	SELECT @error_flag = 1023
	RETURN @error_flag
END


IF @recurring_flag NOT IN (0,1)
BEGIN
	EXEC @result =  glputerr_sp     @client_id, 
					@user_id,
					1024,
					"GLTRXHDR.SP",
					NULL,           
					NULL,           
					NULL,           
					NULL,           
					NULL            
	SELECT @error_flag = 1024
	RETURN @error_flag
END


IF @repeating_flag NOT IN (0,1)
BEGIN
	EXEC @result =  glputerr_sp     @client_id, 
					@user_id,
					1025,
					"GLTRXHDR.SP",
					NULL,           
					NULL,           
					NULL,           
					NULL,           
					NULL            
	SELECT @error_flag = 1025
	RETURN @error_flag
END


IF @reversing_flag NOT IN (0,1)
BEGIN
	EXEC @result =  glputerr_sp     @client_id, 
					@user_id,
					1026,
					"GLTRXHDR.SP",
					NULL,           
					NULL,           
					NULL,           
					NULL,           
					NULL            
	SELECT @error_flag = 1026
	RETURN @error_flag
END

IF @source_batch_code IS NULL
BEGIN
	SELECT @source_batch_code = " "
END


IF @type_flag NOT BETWEEN 0 and 5
BEGIN
	EXEC @result =  glputerr_sp     @client_id, 
					@user_id,
					1027,
					"GLTRXHDR.SP",
					NULL,           
					NULL,           
					NULL,           
					NULL,           
					NULL            
	SELECT @error_flag = 1027
	RETURN @error_flag
END


IF @intercompany_flag NOT IN (0,1)
BEGIN
	EXEC @result =  glputerr_sp     @client_id, 
					@user_id,
					1069,
					"GLTRXHDR.SP",
					NULL,           
					NULL,           
					NULL,           
					NULL,           
					NULL            
	SELECT @error_flag = 1069
	RETURN @error_flag
END


IF (RTRIM(@company_code) != "") OR (RTRIM(@company_code) IS NOT NULL)
BEGIN
	IF NOT EXISTS (SELECT * FROM glcomp_vw
				WHERE company_code  = @company_code )
	BEGIN
		EXEC @result =  glputerr_sp     @client_id, 
						@user_id,
						1005,
						"GLTRXHDR.SP",
						NULL,           
						@journal_ctrl_num,      
						@company_code,  
						NULL,           
						NULL            
		SELECT @error_flag = 1005
		RETURN @error_flag
	END
END
ELSE
	SELECT @company_code = company_code FROM glco 


IF (RTRIM(@home_cur_code) != "") OR  (RTRIM(@home_cur_code) IS NOT NULL)
BEGIN
	IF NOT EXISTS (SELECT * FROM glcurr_vw
			WHERE currency_code = @home_cur_code )
	BEGIN
		EXEC @result =  glputerr_sp     @client_id, 
						@user_id,
						1009,
						"GLTRXHDR.SP",
						NULL,           
						NULL,           
						NULL,           
						NULL,           
						NULL            
		SELECT @error_flag = 1009
		RETURN @error_flag
	END
END
	SELECT @home_cur_code = home_currency, @oper_cur_code = oper_currency FROM glco 


IF @document_1 IS NULL
BEGIN
	SELECT @document_1 = " "
END


IF NOT EXISTS (SELECT * FROM gltrxtyp
			WHERE trx_type = @trx_type )
BEGIN
	EXEC @result =  glputerr_sp     @client_id, 
					@user_id,
					1010,
					"GLTRXHDR.SP",
					NULL,           
					NULL,           
					NULL,           
					NULL,           
					NULL            
	SELECT @error_flag = 1010
	RETURN @error_flag
END






















IF @hold_flag NOT IN (0,1)
BEGIN
	EXEC @result =  glputerr_sp     @client_id, 
					@user_id,
					1029,
					"GLTRXHDR.SP",
					NULL,           
					NULL,           
					NULL,           
					NULL,           
					NULL            
	SELECT @error_flag = 1029
	RETURN @error_flag
END





IF (RTRIM(@journal_ctrl_num) = "") OR  (RTRIM(@journal_ctrl_num) IS NULL)
BEGIN
	WHILE (1=1)
	BEGIN
		UPDATE  glnumber
		SET     next_jrnl_ctrl_code = next_jrnl_ctrl_code + 1
	
		SELECT @float_buff = NULL

		SELECT  @float_buff = next_jrnl_ctrl_code - 1,
			@char_buff = jrnl_ctrl_code_mask
		FROM    glnumber
	
		IF ( @float_buff IS NULL )
		BEGIN 
			EXEC @result =  glputerr_sp     @client_id, 
							@user_id,
							1015,
							"GLTRXHDR.SP",
							NULL,           
							NULL,           
							NULL,           
							NULL,           
							NULL            
			SELECT @error_flag = 1015
			RETURN @error_flag
		END

		EXEC @result = fmtctlnm_sp @float_buff, @char_buff,
			@journal_ctrl_num OUTPUT, @error_flag OUTPUT

		IF @error_flag <> 0
		BEGIN
			EXEC @result =  glputerr_sp     @client_id, 
							@user_id,
							1015,
							"GLTRXHDR.SP",
							NULL,           
							NULL,           
							NULL,           
							NULL,           
							NULL            
			SELECT @error_flag = 1015
			RETURN @error_flag
		END
	

		IF (NOT EXISTS (SELECT * FROM gltrx
					WHERE journal_ctrl_num = @journal_ctrl_num))
			BREAK
	END
END




ELSE
BEGIN
	IF EXISTS(      SELECT  *
			FROM    gltrx
			WHERE   journal_ctrl_num = @journal_ctrl_num )
	BEGIN
		SELECT @error_flag = 1016
		RETURN @error_flag
	END
END

IF (RTRIM(@batch_code) = "") OR (RTRIM(@batch_code) IS NULL)
BEGIN
	



	SELECT  @user_name = user_name
	FROM    glusers_vw
	WHERE   user_id = @user_id
	
	


	EXEC @result = glnxtbat_sp      @module_id, 
					@source_batch_code, 
					6010, 
					@user_name, 
					@date_applied, 
					@company_code, 
					@batch_code output,
					@org_id  
			

	IF ( @result != 0 )
	BEGIN
		SELECT @error_flag = @result
		RETURN @error_flag
	END     
	




	UPDATE  batchctl
	SET     posted_flag = @posted_flag,
		process_group_num = @process_ctrl_num
	WHERE   batch_ctrl_num = @batch_code
END



INSERT  gltrx(
	journal_type,           journal_ctrl_num,       journal_description,    
	date_entered,           date_applied,           recurring_flag,
	repeating_flag,         reversing_flag,         hold_flag,              
	posted_flag,            date_posted,            source_batch_code,
	batch_code,             type_flag,              intercompany_flag,
	company_code,           app_id,                 home_cur_code,
	document_1,             trx_type,               user_id,
	source_company_code,    process_group_num,      oper_cur_code,
	org_id,					interbranch_flag)									
VALUES (@journal_type,          @journal_ctrl_num,      @journal_description,   
	@date_entered,          @date_applied,          @recurring_flag,
	@repeating_flag,        @reversing_flag,        @hold_flag,
	@posted_flag,           0,                      @source_batch_code,
	@batch_code,            @type_flag,             @intercompany_flag,
	@company_code,          @module_id,             @home_cur_code,
	@document_1,            @trx_type,              @user_id,
	" ",                    @process_ctrl_num,      @oper_cur_code,
	@org_id,				@interbranch_flag)									

IF @@rowcount = 0
BEGIN
	EXEC @result =  glputerr_sp     @client_id, 
					@user_id,
					1016,
					"GLTRXHDR.SP",
					NULL,           
					NULL,           
					NULL,           
					NULL,           
					NULL            
	SELECT @error_flag = 1016
	RETURN @error_flag
END

SELECT @error_flag = 0
RETURN @error_flag

GO
GRANT EXECUTE ON  [dbo].[gltrxhdr_sp] TO [public]
GO
