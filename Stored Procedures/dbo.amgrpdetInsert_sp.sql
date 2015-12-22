SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amgrpdetInsert_sp]
(
	@group_id 	smSurrogateKey,
	@sequence_id 	smCounter,
	@group_text 	smStringText
)
AS
 
INSERT INTO amgrpdet
(
	group_id,
	sequence_id,
	group_text
)
VALUES
(
	@group_id,
	@sequence_id,
	@group_text
)
 
RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amgrpdetInsert_sp] TO [public]
GO
