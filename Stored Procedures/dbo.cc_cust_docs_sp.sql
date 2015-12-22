SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_cust_docs_sp]
	 @doc_ctrl_num varchar(16),
	@cust_code varchar(9) = NULL,
	@direction tinyint = 0

AS
set rowcount 50
IF @direction = 0
	select customer_code "Cust. Code", customer_name "Customer Name"
	from arcust
	where customer_code in (select distinct customer_code
			from artrx where doc_ctrl_num = @doc_ctrl_num)
	order by customer_code

IF @direction = 1
	select customer_code "Cust. Code", customer_name "Customer Name"
	from arcust
	where customer_code in (select distinct customer_code
			from artrx where doc_ctrl_num = @doc_ctrl_num
			and customer_code <= @cust_code)
	order by customer_code DESC

IF @direction = 2
	select customer_code "Cust. Code", customer_name "Customer Name"
	from arcust
	where customer_code in (select distinct customer_code
			from artrx where doc_ctrl_num = @doc_ctrl_num
			and customer_code >= @cust_code)
	order by customer_code ASC

set rowcount 0
GO
GRANT EXECUTE ON  [dbo].[cc_cust_docs_sp] TO [public]
GO
