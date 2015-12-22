SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_3pl_parse_formula]
	@usage_area	varchar(30),
	@formula 	varchar(7650),
	@location	varchar(10)
AS

DECLARE @temp_table_name varchar(50),
	@exec_statement  varchar(1200),
	@template_name varchar(30),
	@fill_buffer   varchar(255),
	@i             int,
	@char          char(1)

IF @usage_area NOT IN ('3PLSETUP', '3PLPROCESS', '3PLQUOTE')
BEGIN
	RAISERROR('Invalid usage area defined in parsing formula', 16, 1)
END

SELECT @temp_table_name = 
	CASE WHEN @usage_area = '3PLSETUP'
		THEN '#selected_formula'

	     WHEN @usage_area = '3PLPROCESS'
		THEN '#processing_selected_formula'

	     WHEN @usage_area = '3PLQUOTE'
		THEN '#quote_selected_formula'
	END

SELECT @exec_statement = 'TRUNCATE TABLE ' + @temp_table_name
EXEC(@exec_statement)

SELECT @fill_buffer = ''
SELECT @i           = 1

WHILE @i < len(@formula + 'z')
BEGIN
	SELECT @char = SUBSTRING(@formula, @i, 1)
 
	IF @char IN('(', ')', '+', '-', '*', '/')	
	BEGIN
		SELECT @template_name = LTRIM(RTRIM(@fill_buffer))
		SELECT @fill_buffer = ''	

		IF @template_name != ''
		BEGIN
			SELECT @exec_statement = 'INSERT INTO ' + @temp_table_name  + '(selected, [description], location)
							SELECT template_name, template_desc, location
							  FROM tdc_3pl_templates (NOLOCK) 
							WHERE template_name = ' + '''' + @template_name + '''' + 
							 ' AND location = ' + '''' + @location + ''''
			EXEC(@exec_statement)
		END

		SELECT @exec_statement = 'INSERT INTO ' + @temp_table_name  + '(selected, [description], location)
						SELECT ' + '''' + @char + '''' + ', NULL, ' + '''' + @location + ''''
		EXEC(@exec_statement)
	END
	ELSE
		SELECT @fill_buffer = @fill_buffer + @char
	
	SELECT @i = @i + 1
END

IF LTRIM(RTRIM(@fill_buffer)) != ''
BEGIN
	SELECT @template_name = LTRIM(RTRIM(@fill_buffer))

	SELECT @exec_statement = 'INSERT INTO ' + @temp_table_name  + '(selected, [description], location)
					SELECT template_name, template_desc, location
					  FROM tdc_3pl_templates (NOLOCK) 
					WHERE template_name = ' + '''' + @template_name + '''' + 
					 ' AND location = ' + '''' + @location + ''''
	EXEC(@exec_statement)
END
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_parse_formula] TO [public]
GO
