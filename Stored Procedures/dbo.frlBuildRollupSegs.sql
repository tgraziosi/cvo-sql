SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[frlBuildRollupSegs] @NatSegNum tinyint, @MaxSegs tinyint
AS
BEGIN

	DECLARE
		@Seg1Start	tinyint,
		@Seg1Len		tinyint,
		@Seg2Start	tinyint,
		@Seg2Len		tinyint,
		@Seg3Start	tinyint,
		@Seg3Len		tinyint,
		@Seg4Start	tinyint,
		@Seg4Len		tinyint

	/* Find segment start and length for each segment */
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

	/* Build frl_acct_seg records */
	if @NatSegNum = 1
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg2Start, @Seg2Len) +
					substring(acct_code, @Seg3Start, @Seg3Len) +
					substring(acct_code, @Seg4Start, @Seg4Len), 2, 1,
					acct_id, summary_code, 1
		FROM		glsummnt, frl_acct_code
		WHERE		glsummnt.summary_code = frl_acct_code.acct_code
		AND		rollup_level = 1
		AND		@MaxSegs >= 2

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg3Start, @Seg3Len) +
					substring(acct_code, @Seg2Start, @Seg2Len) +
					substring(acct_code, @Seg4Start, @Seg4Len), 3, 1,
					acct_id, summary_code, 1
		FROM		glsummnt, frl_acct_code
		WHERE		glsummnt.summary_code = frl_acct_code.acct_code
		AND		rollup_level = 1
		AND		@MaxSegs >= 3

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg4Start, @Seg4Len) +
					substring(acct_code, @Seg2Start, @Seg2Len) +
					substring(acct_code, @Seg3Start, @Seg3Len), 4, 1,
					acct_id, summary_code, 1
		FROM		glsummnt, frl_acct_code
		WHERE		glsummnt.summary_code = frl_acct_code.acct_code
		AND		rollup_level = 1
		AND		@MaxSegs = 4
	end

	if @NatSegNum = 2
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg3Start, @Seg3Len) +
					substring(acct_code, @Seg4Start, @Seg4Len), 3, 1,
					acct_id, summary_code, 1
		FROM		glsummnt, frl_acct_code
		WHERE		glsummnt.summary_code = frl_acct_code.acct_code
		AND		@MaxSegs >= 3

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg4Start, @Seg4Len) +
					substring(acct_code, @Seg3Start, @Seg3Len), 4, 1,
					acct_id, summary_code, 1
		FROM		glsummnt, frl_acct_code
		WHERE		glsummnt.summary_code = frl_acct_code.acct_code
		AND		@MaxSegs = 4

	end

	if @NatSegNum = 3
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg2Start, @Seg2Len) +
					substring(acct_code, @Seg4Start, @Seg4Len), 2, 1,
					acct_id, summary_code, 1
		FROM		glsummnt, frl_acct_code
		WHERE		glsummnt.summary_code = frl_acct_code.acct_code

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg4Start, @Seg4Len) +
					substring(acct_code, @Seg2Start, @Seg2Len), 4, 1,
					acct_id, summary_code, 1
		FROM		glsummnt, frl_acct_code
		WHERE		glsummnt.summary_code = frl_acct_code.acct_code
		AND		@MaxSegs = 4

	end

	if @NatSegNum = 4
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg2Start, @Seg2Len) +
					substring(acct_code, @Seg3Start, @Seg3Len), 2, 1,
					acct_id, summary_code, 1
		FROM		glsummnt, frl_acct_code
		WHERE		glsummnt.summary_code = frl_acct_code.acct_code

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg3Start, @Seg3Len) +
					substring(acct_code, @Seg2Start, @Seg2Len), 3, 1,
					acct_id, summary_code, 1
		FROM		glsummnt, frl_acct_code
		WHERE		glsummnt.summary_code = frl_acct_code.acct_code

	end
END
GO
GRANT EXECUTE ON  [dbo].[frlBuildRollupSegs] TO [public]
GO
