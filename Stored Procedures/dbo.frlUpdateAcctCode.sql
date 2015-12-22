SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[frlUpdateAcctCode] @OnlyActive tinyint, @NatSegNum tinyint, @MaxSegs tinyint
AS 
BEGIN

	/* Insert frl_acct_code record */
	INSERT	frl_acct_code(
				entity_num, acct_code, acct_type,
				acct_status, acct_desc, normal_bal,
				acct_group,
				nat_seg_code, modify_flag, rollup_level)
	SELECT	1, account_code, account_type,
				2, account_description, 2,
				convert(int, substring(ltrim(str(account_type)),1,1)),
				account_code, 0, 0
	FROM		glchart
	WHERE		@OnlyActive = 0 OR inactive_flag = 0

	/* Update the nat_seg_code if natural segment is not 1 */
	IF (@NatSegNum = 2)
		UPDATE	frl_acct_code
		SET		nat_seg_code = seg2_code + seg1_code + seg3_code + seg4_code
		FROM		frl_acct_code, glchart
		WHERE		acct_code = glchart.account_code
	ELSE IF (@NatSegNum = 3)
		UPDATE	frl_acct_code
		SET		nat_seg_code = seg3_code + seg1_code + seg2_code + seg4_code
		FROM		frl_acct_code, glchart
		WHERE		acct_code = glchart.account_code
	ELSE IF (@NatSegNum = 4)
		UPDATE	frl_acct_code
		SET		nat_seg_code = seg4_code + seg1_code + seg2_code + seg3_code
		FROM		frl_acct_code, glchart
		WHERE		acct_code = glchart.account_code

	/* Reset acct_group and normal_bal flag */
	UPDATE	frl_acct_code
	SET		acct_group = 4
	WHERE		acct_group = 6

	UPDATE	frl_acct_code
	SET		normal_bal = 1
	WHERE		acct_group in (1,5)

	/* Insert Acct Segs */
	EXEC frlBuildAcctSegs @NatSegNum, @MaxSegs

END
GO
GRANT EXECUTE ON  [dbo].[frlUpdateAcctCode] TO [public]
GO
