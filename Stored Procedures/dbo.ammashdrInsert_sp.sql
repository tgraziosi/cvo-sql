SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[ammashdrInsert_sp]
(
	@mass_maintenance_id 	smSurrogateKey,
	@mass_description 	smStdDescription,
	@one_at_a_time 	smLogical,
	@user_id 	smUserID,
	@group_id 	smSurrogateKey,
	@assets_purged 	smLogical,
	@process_start_date 	varchar(30),
	@process_end_date 	varchar(30),
	@error_code 	smErrorCode,
	@error_message 	smErrorLongDesc
)
AS
 
INSERT INTO ammashdr
(
	mass_maintenance_id,
	mass_description,
	one_at_a_time,
	user_id,
	group_id,
	assets_purged,
	process_start_date,
	process_end_date,
	error_code,
	error_message
)
VALUES
(
	@mass_maintenance_id,
	@mass_description,
	@one_at_a_time,
	@user_id,
	@group_id,
	@assets_purged,
	@process_start_date,
	@process_end_date,
	@error_code,
	@error_message
)
 
RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[ammashdrInsert_sp] TO [public]
GO
