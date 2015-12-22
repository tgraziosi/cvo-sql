SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_links_select_sp]	@key_type	int,
					@key_1		varchar(32),
					@companyDB	varchar(255),
					@customer_code varchar(8) = ''

AS

SET NOCOUNT ON

	DECLARE @company_code	varchar(8),

					@created_by varchar(30),
					@updated_by varchar(30)


	CREATE TABLE #comments
	(	company_code varchar(8),
		key_1 varchar(32),
		key_type smallint,
		sequence_id int,
		date_created datetime,
		created_by varchar(255),
		date_updated datetime,
		updated_by varchar(255),
		link_path varchar(255),
		note varchar(255),
		created_by_id int,
		updated_by_id int

	)

	SELECT @company_code = company_code FROM CVO_Control..ewcomp WHERE db_name = @companyDB


	IF @key_type <> 2510
		SELECT @key_1 = trx_ctrl_num 
		FROM artrx 
		WHERE doc_ctrl_num = @key_1

		AND customer_code = @customer_code

	INSERT #comments
	(	company_code,
		key_1,
		key_type,
		sequence_id,
		date_created,
		created_by,
		date_updated,
		updated_by,
		link_path,
		note,
		created_by_id,
		updated_by_id
	)
	SELECT 	company_code, 
		key_1,
		key_type, 		sequence_id, 
		case when date_created > 639906 then convert(datetime, dateadd(dd, date_created - 639906, '1/1/1753')) else date_created end, 
		0,
		case when date_updated > 639906 then convert(datetime, dateadd(dd, date_updated - 639906, '1/1/1753')) else date_updated end, 
		0,
		link_path,
		note,
		created_by,
		updated_by
	FROM	comments
	WHERE	key_type = @key_type
	AND	key_1 = @key_1
	AND	company_code = @company_code
	ORDER BY sequence_id



	UPDATE 	#comments
	SET 		created_by = [user_name] 
	FROM 		CVO_Control..smusers u, #comments c
	WHERE 	[user_id] = c.created_by_id
	AND			c.key_type = @key_type
	AND			c.key_1 = @key_1
	AND			c.company_code = @company_code
	AND			created_by_id <> 1
	
	UPDATE 	#comments
	SET 		updated_by = [user_name] 
	FROM 		CVO_Control..smusers u, #comments c
	WHERE 	[user_id] = c.updated_by_id
	AND			c.key_type = @key_type
	AND			c.key_1 = @key_1
	AND			c.company_code = @company_code
	AND			updated_by_id <> 1

	UPDATE 	#comments
	SET 		created_by = 'sa'
	FROM 		CVO_Control..smusers u, #comments c
	WHERE 	[user_id] = c.created_by_id
	AND			c.key_type = @key_type
	AND			c.key_1 = @key_1
	AND			c.company_code = @company_code
	AND			created_by_id = 1
	
	UPDATE 	#comments
	SET 		updated_by = 'sa'
	FROM 		CVO_Control..smusers u, #comments c
	WHERE 	[user_id] = c.updated_by_id
	AND			c.key_type = @key_type
	AND			c.key_1 = @key_1
	AND			c.company_code = @company_code
	AND			updated_by_id = 1

	SELECT 	company_code, 
		key_1,
		key_type, 		sequence_id, 
		date_created,
		created_by,
		date_updated,
		updated_by,
		link_path,
		note 
	FROM	#comments
	ORDER BY sequence_id

SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_links_select_sp] TO [public]
GO
