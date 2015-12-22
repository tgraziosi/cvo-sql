SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_cf_inhouse_date_sp '001','DIKICGRARS125'

CREATE PROC [dbo].[cvo_cf_inhouse_date_sp]	@location	VARCHAR(10),
										@part_no	VARCHAR(30)
AS
BEGIN

	DECLARE @inhouse_date DATETIME

	SELECT TOP 1 
		@inhouse_date = inhouse_date
	FROM
		dbo.releases (NOLOCK)
	WHERE
		location = @location
		AND part_no = @part_no
		AND [status] = 'O'
		AND quantity > received		
	ORDER BY
		inhouse_date

	SELECT ISNULL(CONVERT(VARCHAR(10),@inhouse_date,101),'')

END
GO
GRANT EXECUTE ON  [dbo].[cvo_cf_inhouse_date_sp] TO [public]
GO
