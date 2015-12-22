SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amgrphdrInsert_sp]
(
	@group_code 	smGroupCode,
	@group_id 	smSurrogateKey,
	@group_description 	smStdDescription,
	@group_edited 	smLogical
)
AS
 
INSERT INTO amgrphdr
(
	group_code,
	group_id,
	group_description,
	group_edited
)
VALUES
(
	@group_code,
	@group_id,
	@group_description,
	@group_edited
)
 
RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amgrphdrInsert_sp] TO [public]
GO
