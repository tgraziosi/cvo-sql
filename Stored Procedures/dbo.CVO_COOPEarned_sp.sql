SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*---------------------------------------------------------------------------------------------
// REVISION HISTORY
// Rev-No	Date		Name		Issue-No			Description
// ------	----------	----------	----------------	----------------------------------------
// CVO01	10/10/2010	EGARCIA		COOP EARNED SP		Creation for custom Explorer View
//---------------------------------------------------------------------------------------------
*/
  
CREATE PROCEDURE [dbo].[CVO_COOPEarned_sp]  @where_clause varchar(8000) = ' '
AS
BEGIN
	DECLARE @customer_code varchar(50),
			@sub1 varchar(50), @sub2 varchar(50),
			@first_quote varchar(50),	
			@local_where varchar(50),
			@second_quote int

	IF (CHARINDEX('customer_code', @where_clause) = 0) 
		SELECT @customer_code='%%'
	ELSE
	BEGIN	
			SELECT @sub1 = SUBSTRING(@where_clause, CHARINDEX('customer_code',@where_clause), DATALENGTH(@where_clause) - CHARINDEX('customer_code',@where_clause) + 1)
			SELECT @first_quote = CHARINDEX("'", @sub1)
			SELECT @sub2 = SUBSTRING (@sub1, @first_quote + 1, DATALENGTH(@sub1) - @first_quote)
		
			SELECT @second_quote = CHARINDEX("'", @sub2)
			SELECT @customer_code = SUBSTRING (@sub2,1, @second_quote -1)
			SELECT @local_where = ' customer_code like "' + @customer_code + '" '
	END
	
	IF @local_where IS NULL 
		SELECT @local_where = ' 0 = 0 '

	----------------------- FINAL SELECT ----------------------------------------------------
	EXEC('SELECT	order_no, order_ext, coop_dollars, customer_code FROM CVO_coop_dollars_history WHERE ' + @local_where)
  
END
GO
GRANT EXECUTE ON  [dbo].[CVO_COOPEarned_sp] TO [public]
GO
