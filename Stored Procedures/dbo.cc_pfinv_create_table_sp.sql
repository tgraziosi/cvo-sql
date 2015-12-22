SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC	[dbo].[cc_pfinv_create_table_sp]

AS

	DECLARE @rptName varchar(255)
	
	BEGIN TRANSACTION 
		UPDATE CVO_Control..rnum 
		SET next_num = (next_num + 1)%10000
		SELECT @rptName = '##' + convert(varchar(16), next_num - 1) 
		FROM CVO_Control..rnum
	COMMIT TRANSACTION 

	SELECT @rptName


GO
GRANT EXECUTE ON  [dbo].[cc_pfinv_create_table_sp] TO [public]
GO
