CREATE TABLE [dbo].[glsummnt]
(
[timestamp] [timestamp] NOT NULL,
[summary_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bal_fwd_flag] [smallint] NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glsummnt_insert] ON [dbo].[glsummnt] FOR INSERT
AS
BEGIN                                                   
	/* FRx glsummnt insert trigger code to keep the server-based GL Index */
	/* up to date when the rollup accounts change.                        */

	/* Halt processing if no records were affected */
	IF (@@ROWCOUNT = 0)
		RETURN

	/* Don't report back to client the number of rows affected */
	/* This may speed up processing */
	SET NOCOUNT ON

	DECLARE
		@NatSegNum	tinyint, 
		@MaxSegs		tinyint,
		@Seg1Start	tinyint,
		@Seg1Len		tinyint,
		@Seg2Start	tinyint,
		@Seg2Len		tinyint,
		@Seg3Start	tinyint,
		@Seg3Len		tinyint,
		@Seg4Start	tinyint,
		@Seg4Len		tinyint

	SELECT	@MaxSegs = max_segs,
				@NatSegNum = natural_seg
	FROM		frl_entity
	WHERE		entity_num = 1

	/* Insert frl_acct_code records */
	INSERT	frl_acct_code(
				entity_num, acct_code, acct_type, acct_status, acct_desc, normal_bal,
				acct_group, nat_seg_code, modify_flag,	rollup_level)
	SELECT	1, summary_code, 0, 2, description, 1,
				0, summary_code, 0, 1
	FROM		inserted

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

	/* Update the nat_seg_code if natural segment is not 1 */
	IF (@NatSegNum = 2)
		UPDATE	frl_acct_code
		SET		nat_seg_code =	substring(acct_code, @Seg2Start, @Seg2Len) +
										substring(acct_code, @Seg1Start, @Seg1Len) +
										substring(acct_code, @Seg3Start, @Seg3Len) +
										substring(acct_code, @Seg4Start, @Seg4Len)
		FROM		frl_acct_code, inserted
		WHERE		acct_code = inserted.summary_code
	ELSE IF (@NatSegNum = 3)
		UPDATE	frl_acct_code
		SET		nat_seg_code =	substring(acct_code, @Seg3Start, @Seg3Len) +
										substring(acct_code, @Seg1Start, @Seg1Len) +
										substring(acct_code, @Seg2Start, @Seg2Len) +
										substring(acct_code, @Seg4Start, @Seg4Len)
		FROM		frl_acct_code, inserted
		WHERE		acct_code = inserted.summary_code
	ELSE IF (@NatSegNum = 4)
		UPDATE	frl_acct_code
		SET		nat_seg_code =	substring(acct_code, @Seg4Start, @Seg4Len) +
										substring(acct_code, @Seg1Start, @Seg1Len) +
										substring(acct_code, @Seg2Start, @Seg2Len) +
										substring(acct_code, @Seg3Start, @Seg3Len)
		FROM		frl_acct_code, inserted
		WHERE		acct_code = inserted.summary_code

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
		FROM		inserted, frl_acct_code
		WHERE		inserted.summary_code = frl_acct_code.acct_code
		AND		@MaxSegs >= 2

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg3Start, @Seg3Len) +
					substring(acct_code, @Seg2Start, @Seg2Len) +
					substring(acct_code, @Seg4Start, @Seg4Len), 3, 1,
					acct_id, summary_code, 1
		FROM		inserted, frl_acct_code
		WHERE		inserted.summary_code = frl_acct_code.acct_code
		AND		@MaxSegs >= 3

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg4Start, @Seg4Len) +
					substring(acct_code, @Seg2Start, @Seg2Len) +
					substring(acct_code, @Seg3Start, @Seg3Len), 4, 1,
					acct_id, summary_code, 1
		FROM		inserted, frl_acct_code
		WHERE		inserted.summary_code = frl_acct_code.acct_code
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
		FROM		inserted, frl_acct_code
		WHERE		inserted.summary_code = frl_acct_code.acct_code
		AND		@MaxSegs >= 3

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg4Start, @Seg4Len) +
					substring(acct_code, @Seg3Start, @Seg3Len), 4, 1,
					acct_id, summary_code, 1
		FROM		inserted, frl_acct_code
		WHERE		inserted.summary_code = frl_acct_code.acct_code
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
		FROM		inserted, frl_acct_code
		WHERE		inserted.summary_code = frl_acct_code.acct_code

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg4Start, @Seg4Len) +
					substring(acct_code, @Seg2Start, @Seg2Len), 4, 1,
					acct_id, summary_code, 1
		FROM		inserted, frl_acct_code
		WHERE		inserted.summary_code = frl_acct_code.acct_code
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
		FROM		inserted, frl_acct_code
		WHERE		inserted.summary_code = frl_acct_code.acct_code

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	substring(acct_code, @Seg3Start, @Seg3Len) +
					substring(acct_code, @Seg2Start, @Seg2Len), 3, 1,
					acct_id, summary_code, 1
		FROM		inserted, frl_acct_code
		WHERE		inserted.summary_code = frl_acct_code.acct_code

	end

END                   
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glsummnt_trigger_1] on [dbo].[glsummnt] FOR DELETE
AS
BEGIN                                                   
	/* FRx glsummnt delete trigger code to keep the server-based GL Index */
	/* up to date when the chart of accounts changes.                     */

	/* Halt processing if no records were affected */
	IF (@@ROWCOUNT = 0)
		RETURN

	/* Don't report back to client the number of rows affected */
	/* This may speed up processing */
	SET NOCOUNT ON

	DELETE	glbal
	FROM		glbal, deleted
	WHERE		glbal.account_code = deleted.summary_code
	AND		balance_type = 2

	DELETE	frl_acct_seg
	FROM		frl_acct_seg s, frl_acct_code c, deleted d
	WHERE		c.acct_code = d.summary_code
	AND		s.acct_id = c.acct_id
	AND		c.rollup_level = 0

	DELETE	frl_acct_code
	FROM		frl_acct_code c, deleted d
	WHERE		c.acct_code = d.summary_code
	AND		rollup_level = 0

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glsummnt_update] on [dbo].[glsummnt] FOR UPDATE
AS
BEGIN                                                   
	/* FRx glsummnt update trigger code to keep the server-based GL Index */
	/* up to date when the rollup accounts change.                        */

	/* Halt processing if no records were affected */
	IF (@@ROWCOUNT = 0)
		RETURN

	/* Don't report back to client the number of rows affected */
	/* This may speed up processing */
	SET NOCOUNT ON

	UPDATE	frl_acct_code
	SET		acct_desc = description
	FROM		inserted
	WHERE		acct_code = summary_code 

END
GO
CREATE UNIQUE CLUSTERED INDEX [glsummnt_ind_0] ON [dbo].[glsummnt] ([summary_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glsummnt] TO [public]
GO
GRANT SELECT ON  [dbo].[glsummnt] TO [public]
GO
GRANT INSERT ON  [dbo].[glsummnt] TO [public]
GO
GRANT DELETE ON  [dbo].[glsummnt] TO [public]
GO
GRANT UPDATE ON  [dbo].[glsummnt] TO [public]
GO
