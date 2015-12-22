SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE	PROCEDURE [dbo].[apchkprd_sp] @period_start_date int
AS
BEGIN
	
	return 0
END
GO
GRANT EXECUTE ON  [dbo].[apchkprd_sp] TO [public]
GO
