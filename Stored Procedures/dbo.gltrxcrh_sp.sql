SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE  PROCEDURE [dbo].[gltrxcrh_sp]
	@process_ctrl_num       varchar(16),
	@init_mode              smallint,
	@module_id              smallint,
	@val_mode               smallint,
	@journal_type           varchar(8),
	@journal_ctrl_num       varchar(16) OUTPUT,
	@journal_description    varchar(40),    
	@date_entered           int,
	@date_applied           int,
	@recurring_flag         smallint,
	@repeating_flag         smallint,
	@reversing_flag         smallint,
	@source_batch_code      varchar(16),
	@type_flag              smallint,
	@company_code           varchar(8),
	@source_company_code    varchar(8),
	@home_cur_code          varchar(8),
	@document_1             varchar(16),
	@trx_type               smallint,
	@user_id                smallint,
	@hold_flag              smallint,
	@oper_cur_code          varchar(8) = NULL,
	@debug                  smallint=0,
	@ib_org_id varchar(30)=NULL,
	@interbranch_flag SMALLINT=0

AS

DECLARE @posted_flag    smallint,
	@max_seq_id     smallint,
	@journal_exists smallint,
	@local_journal_desc	varchar(30),
	@result                 int










SELECT @local_journal_desc = substring(@journal_description, 1, 30)

IF ( @debug > 0 )
	SELECT  '*** gltrxcrh_sp - Entering gltrxcrh_sp'

IF ( @val_mode NOT IN ( 1, 2 ) )
	RETURN  1054
	
IF ( @init_mode NOT IN ( -1, 0 ) )
	RETURN  1055

IF (@oper_cur_code IS NULL)
BEGIN
	SELECT @oper_cur_code = oper_currency
	FROM glco
END

SELECT @journal_exists = 0





IF  (RTRIM( @journal_ctrl_num ) != '' OR RTRIM( @journal_ctrl_num ) IS NOT NULL )
BEGIN

	SELECT @posted_flag = posted_flag
	FROM    gltrx   
	WHERE @journal_ctrl_num = journal_ctrl_num
	AND     @company_code = company_code

	IF @@rowcount > 0 SELECT @journal_exists = 1
END




IF ((RTRIM( @journal_ctrl_num) = '' ) OR (RTRIM( @journal_ctrl_num) IS NULL )
		       OR  (@journal_exists = 1 AND @posted_flag = 1))
BEGIN


	EXEC    @result = gltrxnew_sp   @company_code,
						@journal_ctrl_num       OUTPUT
	IF ( @debug > 3 )
			SELECT  '*** gltrxcrh_sp - Getting new journal ctrl number '+
				@journal_ctrl_num
			
	IF ( @result != 0 )
		RETURN @result
END






IF (DATALENGTH(ISNULL(RTRIM(LTRIM(@ib_org_id)),''))=0) 
BEGIN
	SELECT @ib_org_id = organization_id
	   FROM Organization
	WHERE outline_num = '1'		
END



IF (@journal_exists = 0 OR @posted_flag = 1)
  BEGIN
	


	INSERT  #gltrx(
		journal_type,           journal_ctrl_num,       journal_description,    
		date_entered,           date_applied,           recurring_flag,
		repeating_flag,         reversing_flag,         hold_flag,              
		posted_flag,            date_posted,            source_batch_code,
		batch_code,             type_flag,              intercompany_flag,
		company_code,           app_id,                 home_cur_code,
		document_1,             trx_type,               user_id,
		source_company_code,    process_group_num,      trx_state,
		next_seq_id,            mark_flag,
		oper_cur_code,		org_id, 		interbranch_flag)
	VALUES (@journal_type,          @journal_ctrl_num,      @local_journal_desc,   
		@date_entered,          @date_applied,          @recurring_flag,
		@repeating_flag,        @reversing_flag,        @hold_flag,
		@init_mode,             0,                      @source_batch_code,
		' ',                    @type_flag,             0,
		@company_code,          @module_id,             @home_cur_code,
		@document_1,            @trx_type,              @user_id,
		@source_company_code,   @process_ctrl_num,      0,
		1,                      0, 
		@oper_cur_code,		@ib_org_id, 		@interbranch_flag)

	IF ( @@error != 0 )
		RETURN  1039
		
	IF ( @debug > 3 )
		SELECT  '*** gltrxcrh_sp - Inserted transaction: '+@journal_ctrl_num

	IF ( @val_mode = 1 )
		BEGIN
			EXEC    @result = gltrxval_sp   @company_code,
							@journal_ctrl_num, 
							NULL,
							@debug
			RETURN  @result
		END
END
ELSE
BEGIN


   IF NOT EXISTS (SELECT journal_ctrl_num
				  FROM #gltrx
				  WHERE journal_ctrl_num = @journal_ctrl_num)
	 BEGIN
	  IF (@posted_flag != -1)
	      UPDATE gltrx
		  SET process_group_num = @process_ctrl_num,
		      posted_flag = -1
	  FROM gltrx
	  WHERE journal_ctrl_num = @journal_ctrl_num


	  SELECT  @type_flag = 6
	  SELECT @max_seq_id = ISNULL(max(sequence_id),0) + 1
	  FROM gltrxdet
	  WHERE @journal_ctrl_num = journal_ctrl_num


	INSERT  #gltrx(
		journal_type,           journal_ctrl_num,       journal_description,    
		date_entered,           date_applied,           recurring_flag,
		repeating_flag,         reversing_flag,         hold_flag,              
		posted_flag,            date_posted,            source_batch_code,
		batch_code,             type_flag,              intercompany_flag,
		company_code,           app_id,                 home_cur_code,
		document_1,             trx_type,               user_id,
		source_company_code,    process_group_num,      trx_state,
		next_seq_id,            mark_flag,
		oper_cur_code,		org_id, 		interbranch_flag)
	SELECT  journal_type,           journal_ctrl_num,       journal_description,   
		date_entered,           date_applied,           recurring_flag,
		repeating_flag,         reversing_flag,         hold_flag,
		posted_flag,            date_posted,            source_batch_code,
		batch_code,             @type_flag,             intercompany_flag,
		company_code,           app_id,                 home_cur_code,
		document_1,             trx_type,               user_id,
		source_company_code,    process_group_num,      0,
		@max_seq_id,            0, 
		oper_cur_code, 		org_id, 		interbranch_flag
	FROM gltrx
	WHERE @journal_ctrl_num = journal_ctrl_num
  END
END


IF ( @debug > 0 )
	SELECT  '*** gltrxcrh_sp - Leaving gltrxcrh_sp'

RETURN  0
GO
GRANT EXECUTE ON  [dbo].[gltrxcrh_sp] TO [public]
GO
