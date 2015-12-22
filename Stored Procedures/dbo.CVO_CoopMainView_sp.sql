SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*---------------------------------------------------------------------------------------------
// REVISION HISTORY
// Rev-No	Date		Name		Issue-No	Description
// ------	----------	----------	----------	-----------------------------------------------
// CVO01	10/10/2010	EGARCIA		COOP VIEW	Creation for custom Explorer View
// v1.1		05/07/2012	CTYLER		721			Add coop_ytd field	
// v1.2		12/5/2012	tag						added salesperson code
//---------------------------------------------------------------------------------------------
*/
--exec cvo_coopmainview_sp "customer_name like '%ca%' and salesperson_code like '%bar%'"

CREATE PROC [dbo].[CVO_CoopMainView_sp] @WhereClause varchar(2048)=''
AS
DECLARE		@OrderBy varchar(255) ,
			@customerName varchar(300)

	SELECT @OrderBy = ' order by a.customer_code'

	select @whereclause = replace(@whereclause,'customer_code','c.customer_code')
	select @whereclause = replace(@whereclause,'customer_name','a.customer_name')
	select @whereclause = replace(@whereclause,'salesperson_code','a.salesperson_code')
	select @whereclause = replace(@whereclause,'where','')
	

	
--	SELECT @WhereClause =  'SELECT	DISTINCT c.customer_code, a.customer_name, ISNULL(c.coop_dollars,0) as coop_dollars,
--			ISNULL(c.coop_dollars_prev_year,0) as coop_dollars_prev_year, ISNULL(c.coop_redeemed,0) as coop_redeemed,
--			ISNULL(coop_dollars, 0) + ISNULL(coop_redeemed, 0) as balance FROM cvo_armaster_all c, arcust a 
--			WHERE c.customer_code = a.customer_code	AND c.address_type = 0  
--			AND c.customer_code like ' + @Sub1 + ' AND a.customer_name like ' + @Sub2 + @OrderBy
--
--	SELECT @WhereClause

exec(
--select 
'		SELECT a.salesperson_code, c.customer_code, a.customer_name, ISNULL(c.coop_dollars,0) as coop_dollars,
		ISNULL(c.coop_dollars_prev_year,0) as coop_dollars_prev_year, ISNULL(c.coop_redeemed,0) as coop_redeemed,
		(ISNULL(c.coop_dollars_prev_year,0) + ISNULL(coop_dollars, 0)) - ISNULL(coop_redeemed, 0) as balance, 
		ISNULL(coop_ytd,0) as coop_ytd FROM cvo_armaster_all c (nolock), arcust a (nolock)
		WHERE c.customer_code = a.customer_code	AND c.address_type = 0  
		AND ' + @whereclause + @orderby
)



GO
GRANT EXECUTE ON  [dbo].[CVO_CoopMainView_sp] TO [public]
GO
