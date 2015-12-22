SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[init_date_jul_sp]
AS
DECLARE	@year 		int , 
	@month 		int , 
	@date 		int , 
	@jul_date 	int,
	@date_char 	varchar(10),
	@date_out 	datetime

SELECT 	@jul_date = period_end_date 
FROM 	glco


EXEC appdtjul_sp @year OUTPUT,	@month OUTPUT, @date OUTPUT, @jul_date 

SELECT 	@date_char = CONVERT (VARCHAR(2), @month) + '/' + CONVERT (VARCHAR(2), @date) + '/' + CONVERT (VARCHAR(4), @year)
SELECT @date_out = CONVERT (DATETIME , @date_char)
SELECT @date_out

GO
GRANT EXECUTE ON  [dbo].[init_date_jul_sp] TO [public]
GO
