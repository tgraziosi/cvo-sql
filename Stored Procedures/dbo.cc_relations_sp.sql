SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_relations_sp]
	@customer_code varchar(12),
	@rel_type smallint	



AS

IF @rel_type = 0
	select child, customer_name, relation_code 
	from arnarel, arcust 
	where parent = @customer_code
	and child = customer_code
ELSE
	select parent, customer_name, relation_code 
	from arnarel, arcust 
	where child = @customer_code
	and parent = customer_code

GO
GRANT EXECUTE ON  [dbo].[cc_relations_sp] TO [public]
GO
