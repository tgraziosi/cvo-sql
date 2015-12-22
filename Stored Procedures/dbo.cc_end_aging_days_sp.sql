SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_end_aging_days_sp] 

AS

DECLARE @age_bracket_1		smallint,
	@age_bracket_2		smallint,
	@age_bracket_3		smallint,
	@age_bracket_4		smallint
	

SELECT age_bracket1,
	age_bracket2,
	age_bracket3,
	age_bracket4 
FROM arco

GO
GRANT EXECUTE ON  [dbo].[cc_end_aging_days_sp] TO [public]
GO
