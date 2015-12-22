SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[frlUpdateRollupCode] @NatSegNum tinyint, @MaxSegs tinyint
AS 
BEGIN
	DECLARE
	  @Seg1Start            tinyint,
	  @Seg1Len              tinyint,
	  @Seg2Start            tinyint,
	  @Seg2Len              tinyint,
	  @Seg3Start            tinyint,
	  @Seg3Len              tinyint,
	  @Seg4Start            tinyint,
	  @Seg4Len              tinyint

	/* Insert frl_acct_code records */
	INSERT	frl_acct_code(
				entity_num, acct_code, acct_type, acct_status, acct_desc, normal_bal,
				acct_group, nat_seg_code, modify_flag,	rollup_level)
	SELECT	1, summary_code, 0, 2, description, 1,
				0, summary_code, 0, 1
	FROM		glsummnt

	/* Find segment start and length for each segment */
	IF (@NatSegNum > 1)
	BEGIN
		SELECT	@Seg1Start = 1,
					@Seg1Len = seg_length
		FROM		frl_seg_ctrl
		WHERE		seg_num = 1

		SELECT	@Seg2Start = @Seg1Start + @Seg1Len,
					@Seg2Len = seg_length
		FROM		frl_seg_ctrl
		WHERE		seg_num = 2

		SELECT	@Seg3Start = @Seg2Start + @Seg2Len,
					@Seg3Len = seg_length
		FROM		frl_seg_ctrl
		WHERE		seg_num = 3

		SELECT	@Seg4Start = @Seg3Start + @Seg3Len,
					@Seg4Len = seg_length
		FROM		frl_seg_ctrl
		WHERE		seg_num = 4
	END

	/* Update the nat_seg_code if natural segment is not 1 */
	IF (@NatSegNum = 2)
		UPDATE	frl_acct_code
		SET		nat_seg_code =	substring(acct_code, @Seg2Start, @Seg2Len) +
										substring(acct_code, @Seg1Start, @Seg1Len) +
										substring(acct_code, @Seg3Start, @Seg3Len) +
										substring(acct_code, @Seg4Start, @Seg4Len)
	ELSE IF (@NatSegNum = 3)
		UPDATE	frl_acct_code
		SET		nat_seg_code =	substring(acct_code, @Seg3Start, @Seg3Len) +
										substring(acct_code, @Seg1Start, @Seg1Len) +
										substring(acct_code, @Seg2Start, @Seg2Len) +
										substring(acct_code, @Seg4Start, @Seg4Len)
	ELSE IF (@NatSegNum = 4)
		UPDATE	frl_acct_code
		SET		nat_seg_code =	substring(acct_code, @Seg4Start, @Seg4Len) +
										substring(acct_code, @Seg1Start, @Seg1Len) +
										substring(acct_code, @Seg2Start, @Seg2Len) +
										substring(acct_code, @Seg3Start, @Seg3Len)

	/* Insert Acct Segs */
	EXEC frlBuildRollupSegs	@NatSegNum, @MaxSegs

END
GO
GRANT EXECUTE ON  [dbo].[frlUpdateRollupCode] TO [public]
GO
