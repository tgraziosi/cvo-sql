SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                















































CREATE PROCEDURE [dbo].[glacsum_sp] 
	@module_id              int,
	@journal_ctrl_num       varchar(16),
	@rec_company_code       varchar(8),
	@company_id             smallint,
	@account_code           varchar(32),
	@description            varchar(40),
	@document_1             varchar(16),
	@document_2             varchar(16),
	@reference_code         varchar(32),
	@balance                float,
	@nat_balance            float,
	@nat_cur_code           varchar(8),
	@rate                   float,
	@trx_type               smallint,
	@offset_flag            smallint,
	@balance_oper           float,         
	@rate_oper              float,   
	@rate_type_home         varchar(8),   
	@rate_type_oper         varchar(8),   
	@seg1_code              varchar(32),
	@seg2_code              varchar(32),
	@seg3_code              varchar(32),
	@seg4_code              varchar(32),
	@seq_ref_id             int=0,
	@error_flag             int=0   OUTPUT,
	@org_id			varchar(30) =''

AS
SELECT  @error_flag = 0

DECLARE @ret_status             int, 
	@sqid                   int,
	@error_code             int,
	@update_seq_id          int,
	@count_seq_id           int,
	@insert_required        tinyint,
	@client_id              varchar(20),
	@account_format_mask    varchar(35),
	@E_CANT_INS_GLTRXDET    int,
	@E_INVALID_MODULE       int,
	@E_INVALID_JRNL_CTRL    int,    
	@E_INVALID_COMPCODE     int,    
	@E_INVALID_COMPID       int,    
	@E_INVALID_ACCTCODE     int,    
	@E_INVALID_DOC_NUM      int,    
	@E_INVALID_NATCODE      int,    
	@E_INVALID_TRXTYPE      int,    
	@E_INVALID_OFFSET       int,    
	@E_INVALID_SEGCODE      int,
	@curr_company_id        smallint,
	@str_msg		varchar(255)

	     


      
SELECT  @curr_company_id = company_id
FROM    glco
	
SELECT  @client_id = "POSTTRX"



SELECT  @E_CANT_INS_GLTRXDET = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_CANT_INS_GLTRXDET"

SELECT  @E_INVALID_MODULE = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_INVALID_MODULE"

SELECT  @E_INVALID_JRNL_CTRL = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_INVALID_JRNL_CTRL"

SELECT  @E_INVALID_COMPCODE = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_INVALID_COMPCODE"

SELECT  @E_INVALID_COMPID = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_INVALID_COMPID"

SELECT  @E_INVALID_ACCTCODE = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_INVALID_ACCTCODE"

SELECT  @E_INVALID_DOC_NUM = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_INVALID_DOC_NUM"

SELECT  @E_INVALID_NATCODE = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_INVALID_NATCODE"

SELECT  @E_INVALID_TRXTYPE = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_INVALID_TRXTYPE"

SELECT  @E_INVALID_OFFSET = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_INVALID_OFFSET"

SELECT  @E_INVALID_SEGCODE = e_code
FROM    glerrdef
WHERE   e_sdesc = "E_INVALID_SEGCODE"




IF      @seq_ref_id IS NULL
	SELECT  @seq_ref_id = 0

IF      @module_id <> 6000
	SELECT  @offset_flag = 0

IF      @description IS NULL 
	SELECT  @description = ""
	
IF      @document_1 IS NULL 
	SELECT  @document_1 = ""






IF NOT EXISTS (SELECT * FROM glappid
			WHERE app_id = @module_id)
BEGIN
	EXEC @ret_status = glputerr_sp  @client_id, 
					1, 
					@E_INVALID_MODULE, 
					"glacsum.sp", 
					NULL,
					@journal_ctrl_num, 
					NULL, 
					@module_id, 
					NULL

	SELECT @error_flag = @E_INVALID_MODULE
	RETURN @error_flag
END


IF NOT EXISTS (SELECT * FROM gltrx
			WHERE journal_ctrl_num = @journal_ctrl_num)
BEGIN
	EXEC @ret_status = glputerr_sp  @client_id, 
					1, 
					@E_INVALID_JRNL_CTRL, 
					"glacsum.sp", 
					NULL,
					@journal_ctrl_num, 
					NULL, 
					NULL, 
					NULL

	SELECT @error_flag = @E_INVALID_JRNL_CTRL
	RETURN @error_flag
END


IF @rec_company_code = ' '
   SELECT @rec_company_code = company_code FROM glco

IF NOT EXISTS (SELECT * FROM glcomp_vw
			WHERE company_code  = @rec_company_code )
BEGIN
	EXEC @ret_status = glputerr_sp  @client_id, 
					1, 
					@E_INVALID_COMPCODE, 
					"glacsum.sp", 
					NULL,
					@journal_ctrl_num, 
					@rec_company_code, 
					NULL, 
					NULL

	SELECT @error_flag = @E_INVALID_COMPCODE
	RETURN @error_flag
END


IF @company_id = 0
   SELECt @company_id = company_id FROM glco
				   WHERE company_code = @rec_company_code
IF NOT EXISTS (SELECT * FROM glcomp_vw
			WHERE company_id  = @company_id )
BEGIN
	EXEC @ret_status = glputerr_sp  @client_id, 
					1, 
					@E_INVALID_COMPID, 
					"glacsum.sp", 
					NULL,
					@journal_ctrl_num, 
					NULL, 
					@company_id, 
					NULL

	SELECT @error_flag = @E_INVALID_COMPID
	RETURN @error_flag
END




IF ( @company_id = @curr_company_id AND 
   NOT EXISTS (SELECT * FROM glchart WHERE account_code = @account_code ) )
BEGIN
	EXEC @ret_status = glputerr_sp  @client_id, 
					1, 
					@E_INVALID_ACCTCODE, 
					"glacsum.sp", 
					NULL,
					@journal_ctrl_num, 
					@account_code, 
					NULL, 
					NULL

	SELECT @error_flag = @E_INVALID_ACCTCODE
	RETURN @error_flag
END


IF      @document_2 IS NULL
BEGIN
	EXEC @ret_status = glputerr_sp  @client_id, 
					1, 
					@E_INVALID_DOC_NUM, 
					"glacsum.sp", 
					NULL,
					@journal_ctrl_num, 
					NULL, 
					NULL, 
					NULL

	SELECT @error_flag = @E_INVALID_DOC_NUM
	RETURN @error_flag
END



if @nat_cur_code = ' '
	SELECT @nat_cur_code = home_currency FROM glco 
					    WHERE company_id = @company_id
IF NOT EXISTS (SELECT * FROM glcurr_vw
			WHERE currency_code = @nat_cur_code )
BEGIN
	EXEC @ret_status = glputerr_sp  @client_id, 
					1, 
					@E_INVALID_NATCODE, 
					"glacsum.sp", 
					NULL,
					@journal_ctrl_num, 
					@nat_cur_code, 
					NULL, 
					NULL

	SELECT @error_flag = @E_INVALID_NATCODE
	RETURN @error_flag
END


IF NOT EXISTS (SELECT * FROM gltrxtyp
			WHERE trx_type = @trx_type )
BEGIN
	EXEC @ret_status = glputerr_sp  @client_id, 
					1, 
					@E_INVALID_TRXTYPE, 
					"glacsum.sp", 
					NULL,
					@journal_ctrl_num, 
					NULL, 
					@trx_type, 
					NULL

	SELECT @error_flag = @E_INVALID_TRXTYPE
	RETURN @error_flag
END


IF @offset_flag not in (0,1)
BEGIN
	EXEC @ret_status = glputerr_sp  @client_id, 
					1, 
					@E_INVALID_OFFSET, 
					"glacsum.sp", 
					NULL,
					@journal_ctrl_num, 
					NULL, 
					@offset_flag, 
					NULL

	SELECT @error_flag = @E_INVALID_OFFSET
	RETURN @error_flag
END

IF ( @company_id = @curr_company_id AND 
   ( @seg1_code IS NOT NULL OR
     @seg2_code IS NOT NULL OR
     @seg3_code IS NOT NULL OR
     @seg4_code IS NOT NULL ) )
BEGIN
	
	IF RTRIM(@seg1_code) != "" OR RTRIM(@seg2_code) != ""
	OR RTRIM(@seg3_code) != "" OR RTRIM(@seg4_code) != ""
	BEGIN
		IF NOT EXISTS ( SELECT * FROM glchart
				WHERE account_code = @account_code
				AND seg1_code = @seg1_code
				AND seg2_code = @seg2_code
				AND seg3_code = @seg3_code
				AND seg4_code = @seg4_code)
		BEGIN
			EXEC @ret_status = glputerr_sp  @client_id, 
							1, 
							@E_INVALID_SEGCODE, 
							"glacsum.sp", 
							NULL, 
							@journal_ctrl_num, 
							NULL, 
							NULL, 
							NULL

			SELECT @error_flag = @E_INVALID_SEGCODE
			RETURN @error_flag
		END
	END
	ELSE
	


	BEGIN
		SELECT @account_format_mask = account_format_mask
		FROM glco
		WHERE company_id = @company_id

		EXEC @ret_status = glprsact_sp @account_code, 
		    @account_format_mask,
		    @seg1_code = @seg1_code OUTPUT,
		    @seg2_code = @seg2_code OUTPUT,                  
		    @seg3_code = @seg3_code OUTPUT,                  
		    @seg4_code = @seg4_code OUTPUT

		IF @ret_status <> 0
		BEGIN
			SELECT @error_flag = @ret_status
			RETURN @error_flag
		END
	END
END 
ELSE IF ( @company_id != @curr_company_id )
BEGIN
	


	SELECT  @account_format_mask = account_format_mask
	FROM    glcomp_vw
	WHERE   company_code = @rec_company_code

	EXEC @ret_status = glprsact_sp @account_code, 
		@account_format_mask,
		@seg1_code = @seg1_code OUTPUT,
		@seg2_code = @seg2_code OUTPUT,                  
		@seg3_code = @seg3_code OUTPUT,                  
		@seg4_code = @seg4_code OUTPUT

	IF @ret_status <> 0
	BEGIN
		SELECT @error_flag = @ret_status
		RETURN @error_flag
	END
END




SELECT  @insert_required = 1




IF (    @company_id = @curr_company_id 
	AND
	EXISTS( SELECT  *  
		FROM    glacsum 
		WHERE   account_code = @account_code 
		AND     app_id = @module_id ) )
BEGIN
	SELECT  @update_seq_id = NULL

	SELECT  @update_seq_id = sequence_id 
	FROM    gltrxdet        
	WHERE   journal_ctrl_num = @journal_ctrl_num
	AND     account_code = @account_code 
	AND     rec_company_code = @rec_company_code 
	AND     reference_code = @reference_code
	AND     nat_cur_code = @nat_cur_code
	AND     rate = @rate
	AND     trx_type = @trx_type
	AND     offset_flag = @offset_flag

	IF ( @update_seq_id IS NOT NULL )
	BEGIN
		SELECT  @insert_required = 0

		


		SELECT  @count_seq_id = COUNT(*)
		FROM    gltrxdet
		WHERE   journal_ctrl_num = @journal_ctrl_num
		AND     sequence_id = @update_seq_id

		IF ( @count_seq_id > 1 )
		BEGIN

			EXEC appgetstring_sp "STR_DUPLICATE_SEQ", @str_msg OUT

			EXEC @ret_status =      glputerr_sp
						@client_id, 
						1,              
						@E_CANT_INS_GLTRXDET,
						"GLACSUM.SP",
						NULL,           
						@journal_ctrl_num, 
						@str_msg,
						@update_seq_id, 
						@module_id      
			SELECT  @ret_status = @E_CANT_INS_GLTRXDET
		END
		





		UPDATE  gltrxdet
		SET     balance = balance + @balance,
			nat_balance = nat_balance + @nat_balance,
			balance_oper = balance_oper + @balance_oper,
			document_1 = " ",
			document_2 = " ",
			description = " "
		WHERE   journal_ctrl_num = @journal_ctrl_num
		AND     sequence_id = @update_seq_id

		SELECT  @error_code = @@error
	END

END

IF ( @insert_required = 1 )
BEGIN
	

	SELECT  @sqid = ISNULL(MAX( sequence_id ),0) + 1
	FROM    gltrxdet        
	WHERE   journal_ctrl_num = @journal_ctrl_num

	


	INSERT  gltrxdet (
		journal_ctrl_num,      
		sequence_id,    
		rec_company_code,
		company_id ,            
		account_code,   
		description,
		document_1,             
		document_2,     
		reference_code,
		balance,                
		nat_balance,    
		nat_cur_code,
		rate,                   
		posted_flag,    
		date_posted,
		trx_type,               
		offset_flag,    
		seg1_code,
		seg2_code,              
		seg3_code,      
		seg4_code,
		seq_ref_id,
		balance_oper,
		rate_oper,
		rate_type_home,
		rate_type_oper,
		org_id )

	VALUES (@journal_ctrl_num,      
		@sqid,          
		@rec_company_code,
		@company_id ,           
		@account_code,  
		@description,
		@document_1,            
		@document_2,    
		@reference_code,
		@balance,               
		@nat_balance,   
		@nat_cur_code,
		@rate,                  
		0,              
		0,
		@trx_type,              
		@offset_flag,   
		@seg1_code,
		@seg2_code,             
		@seg3_code,     
		@seg4_code,
		@seq_ref_id,
		@balance_oper,
		@rate_oper,
		@rate_type_home,
		@rate_type_oper,
		@org_id )

		SELECT  @error_code = @@error
END

SELECT  @ret_status = 0

IF ( @error_code != 0 )
BEGIN
	
	EXEC @ret_status =      glputerr_sp     @client_id, 
						1,              
						@E_CANT_INS_GLTRXDET,
						"GLACSUM.SP",
						NULL,           
						@journal_ctrl_num, 
						NULL,           
						@update_seq_id, 
						@module_id      
	SELECT  @ret_status = @E_CANT_INS_GLTRXDET
END

RETURN  @ret_status
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glacsum_sp] TO [public]
GO
