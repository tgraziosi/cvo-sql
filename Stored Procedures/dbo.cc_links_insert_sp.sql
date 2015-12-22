SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_links_insert_sp]	@link_path	varchar(255),
					@note		varchar(255),
					@key_type	int,
					@key_1		varchar(32),
					@companyDB	varchar(255),
					@customer_code varchar(8)

AS
	DECLARE @company_code	varchar(8),
		@today		int,
		@sequence_id	int,
		@user_id	int,
		@user_name	varchar(255),
		@domain			varchar(255)

	SELECT @company_code = company_code FROM CVO_Control..ewcomp WHERE db_name = @companyDB
	SELECT @today = datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906
	SELECT @user_id = user_id()







	SELECT @user_name = LTRIM(RTRIM(loginame)), @domain = LTRIM(RTRIM(nt_domain)) 
	FROM master.dbo.sysprocesses 
	WHERE spid = @@SPID 

	SELECT @user_name = replace(@user_name, @domain, '')
	SELECT @user_name = replace(@user_name, '\', '')


	IF @key_type <> 2510
		SELECT @key_1 = trx_ctrl_num 
		FROM artrx 
		WHERE doc_ctrl_num = @key_1 

		AND customer_code = @customer_code



	SELECT @sequence_id = MAX(sequence_id) + 1 
	FROM comments 
	WHERE company_code = @company_code 
	AND key_1 = @key_1 
	AND key_type = @key_type

	IF @sequence_id IS NULL
		SELECT @sequence_id = 1
	
	INSERT CVO_Control..comments( company_code, 
			 key_1,
			 key_type, 			 sequence_id, 
			 date_created, 
			 created_by, 
			 date_updated, 
			 updated_by, 
			 link_path,
			 note)
	SELECT	@company_code,
		@key_1,
		@key_type,		@sequence_id,
		@today,
		user_id,
		@today,
		user_id,
		@link_path,
		@note 
	FROM	CVO_Control..smusers
	WHERE	user_name = @user_name
		
GO
GRANT EXECUTE ON  [dbo].[cc_links_insert_sp] TO [public]
GO
