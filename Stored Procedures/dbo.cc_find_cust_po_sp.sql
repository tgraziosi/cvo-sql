SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_find_cust_po_sp] 
	 @cust_po_num varchar(20)

AS

	SET rowcount 1

	SELECT 	MIN(customer_code)
	FROM 		artrx 
	WHERE 	cust_po_num = @cust_po_num
	AND 		void_flag = 0
	AND		ISNULL(DATALENGTH(LTRIM(RTRIM(cust_po_num))),0) > 0

	SET rowcount 0
GO
GRANT EXECUTE ON  [dbo].[cc_find_cust_po_sp] TO [public]
GO
