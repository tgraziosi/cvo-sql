SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cc_aging_brackets_sp] 

AS

DECLARE @age_bracket_1		smallint,
	@age_bracket_2		smallint,
	@age_bracket_3		smallint,
	@age_bracket_4		smallint,
	@age_bracket_5		smallint




























	SELECT 	'Current',
					'1 - 30 Days Over',
					'31 - 60 Days Over',
					'61 - 90 Days Over',
					'91 - 120 Days Over',
					'120 + Days Over',
					'Future'
					
					

GO
GRANT EXECUTE ON  [dbo].[cc_aging_brackets_sp] TO [public]
GO
