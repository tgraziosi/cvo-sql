SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammashdrAll_sp]
AS
 
SELECT
	timestamp,
	mass_maintenance_id,
	mass_description,
	one_at_a_time,
	user_id,
	group_id,
	assets_purged,
	process_start_date = convert(char(8),process_start_date, 112),
	process_end_date = convert(char(8),process_end_date, 112),
	error_code,
	error_message
FROM	ammashdr
ORDER BY	mass_maintenance_id
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[ammashdrAll_sp] TO [public]
GO
