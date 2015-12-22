SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[frlBuildAcctSegs] @NatSegNum tinyint, @MaxSegs tinyint
AS
BEGIN

	/* Build frl_acct_seg records */
	if @NatSegNum = 1
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg2_code + seg3_code + seg4_code, 2, 1,
					acct_id, account_code, 0
		FROM		glchart, frl_acct_code
		WHERE		glchart.account_code = frl_acct_code.acct_code
		AND		@MaxSegs >= 2

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg3_code + seg2_code + seg4_code, 3, 1,
					acct_id, account_code, 0
		FROM		glchart, frl_acct_code
		WHERE		glchart.account_code = frl_acct_code.acct_code
		AND		@MaxSegs >= 3

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg4_code + seg2_code + seg3_code, 4, 1,
					acct_id, account_code, 0
		FROM		glchart, frl_acct_code
		WHERE		glchart.account_code = frl_acct_code.acct_code
		AND		@MaxSegs = 4
	end

	if @NatSegNum = 2
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg3_code + seg4_code, 3, 1,
					acct_id, account_code, 0
		FROM		glchart, frl_acct_code
		WHERE		glchart.account_code = frl_acct_code.acct_code
		AND		@MaxSegs >= 3

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg4_code + seg3_code, 4, 1,
					acct_id, account_code, 0
		FROM		glchart, frl_acct_code
		WHERE		glchart.account_code = frl_acct_code.acct_code
		AND		@MaxSegs = 4

	end

	if @NatSegNum = 3
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg2_code + seg4_code, 2, 1,
					acct_id, account_code, 0
		FROM		glchart, frl_acct_code
		WHERE		glchart.account_code = frl_acct_code.acct_code

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg4_code + seg2_code, 4, 1,
					acct_id, account_code, 0
		FROM		glchart, frl_acct_code
		WHERE		glchart.account_code = frl_acct_code.acct_code
		AND		@MaxSegs = 4

	end

	if @NatSegNum = 4
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg2_code + seg3_code, 2, 1,
					acct_id, account_code, 0
		FROM		glchart, frl_acct_code
		WHERE		glchart.account_code = frl_acct_code.acct_code

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg3_code + seg2_code, 3, 1,
					acct_id, account_code, 0
		FROM		glchart, frl_acct_code
		WHERE		glchart.account_code = frl_acct_code.acct_code

	end
END
GO
GRANT EXECUTE ON  [dbo].[frlBuildAcctSegs] TO [public]
GO
