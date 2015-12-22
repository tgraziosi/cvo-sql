SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[frlBuildGLIX] @OnlyActive tinyint
AS
BEGIN
	DECLARE
		@EntityCode		char(16),
		@MaxSegs			smallint,
		@NatSegNum		smallint

	/* Insert or update entity record */
	IF NOT EXISTS (SELECT * FROM frl_entity WHERE entity_num = 1)
		INSERT	frl_entity(
					entity_num, entity_code, entity_desc, 
					only_active_accts, index_built)
		SELECT	1, company_code, company_name,
					@OnlyActive, 0
		FROM		glco
	ELSE
		UPDATE	frl_entity
		SET		index_built = 0,
					only_active_accts = @OnlyActive
		WHERE		entity_num = 1

	/* Remove all old records */
	TRUNCATE TABLE frl_seg_desc
	TRUNCATE TABLE frl_seg_ctrl
	TRUNCATE TABLE frl_acct_seg
	TRUNCATE TABLE frl_acct_code

	/* Build new segment control records */
	INSERT	frl_seg_ctrl(
				entity_num, seg_num, seg_desc, seg_length)
	SELECT	1, acct_level, description, length - start_col + 1
	FROM		glaccdef
  
	/* Find max segments */
	SELECT	@MaxSegs = max(acct_level)
	FROM		glaccdef

	/* Find natural segment */
	SELECT	@NatSegNum = acct_level
	FROM		glaccdef
	WHERE		natural_acct_flag = 1

	/* Build segment description table */
	EXEC frlBuildSegDesc

	/* Build account codes and segments */
	EXEC frlUpdateAcctCode @OnlyActive, @NatSegNum, @MaxSegs

	/* Build rollup codes and segments */
	EXEC frlUpdateRollupCode @NatSegNum, @MaxSegs

	/* Update frl_entity to reflex built done */
	UPDATE	frl_entity
	SET		index_built = 1,
				max_segs = @MaxSegs,
				natural_seg = @NatSegNum
	WHERE		entity_num = 1

	/* Update statistics */
	UPDATE STATISTICS frl_entity
	UPDATE STATISTICS frl_seg_ctrl
	UPDATE STATISTICS frl_seg_desc
	UPDATE STATISTICS frl_acct_code
	UPDATE STATISTICS frl_acct_seg
 
END
GO
GRANT EXECUTE ON  [dbo].[frlBuildGLIX] TO [public]
GO
