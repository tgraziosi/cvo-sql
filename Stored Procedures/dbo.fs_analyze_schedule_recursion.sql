SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_analyze_schedule_recursion]
	(
	@sched_id	INT
	)
WITH ENCRYPTION
AS
BEGIN

-- DESCRIPTION: This procedure analyzes the build plans used
-- in a scenario. The output format of this procedure MUST 
-- match the columns used in the INSERT-EXECUTE into the
-- #analysis table in the procedure fs_analyze_schedule

DECLARE	@recurse_id	INT,
	@asm_no		VARCHAR(30),
	@sub_no		VARCHAR(30),
	@pass		INT,
	@part_no	VARCHAR(30)

-- Create list of parts to check
CREATE TABLE #list
	(
	part_no		VARCHAR(20)
	)

-- Create recursion stack
CREATE TABLE #recurse
	(
	recurse_id	INT IDENTITY,
	part_no		VARCHAR(20),
	pass		INT DEFAULT 0
	)

CREATE CLUSTERED INDEX recurse ON #recurse(recurse_id)

-- Get list of parts to check
INSERT	#list(part_no)
SELECT	DISTINCT SO.part_no
FROM	dbo.sched_order SO
WHERE	SO.sched_id = @sched_id
AND	SO.part_no IS NOT NULL

CREATE CLUSTERED INDEX part ON #list(part_no)

-- Get the first part to check
SELECT	@asm_no=MIN(L.part_no)
FROM	#list L

WHILE @asm_no IS NOT NULL
	BEGIN
	-- Insert first part
	INSERT	#recurse(part_no)
	VALUES	(@asm_no)

	-- Get first item
	SELECT	@recurse_id=MAX(R.recurse_id)
	FROM	#recurse R

	-- Keep processing until table is empty
	WHILE @recurse_id IS NOT NULL
		BEGIN
		-- Get item information
		SELECT	@pass=R.pass,
			@sub_no=R.part_no
		FROM	#recurse R
		WHERE	R.recurse_id = @recurse_id
		
		-- Has it been touched?
		IF @pass > 0
			-- We have been here before... remove it
			DELETE	#recurse
			FROM	#recurse R
			WHERE	R.recurse_id = @recurse_id
		ELSE
			BEGIN
			-- We have not been here before,
			-- mark this node as having been touched
			UPDATE	#recurse
			SET	pass = 1
			FROM	#recurse R
			WHERE	R.recurse_id = @recurse_id

			-- Find a part in this build plan that we have already traversed
			SELECT	@part_no=WP.part_no
			FROM	dbo.what_part WP,
				#recurse R
			WHERE	WP.asm_no = @sub_no
			AND	R.pass = 1
			AND	R.part_no = WP.part_no

			-- Did we find a bad part?
			IF @@rowcount > 0
				BEGIN
				SELECT  'F',			-- source_flag
					'Order #'		-- summary
					+ CONVERT(VARCHAR(8),SO.order_no)+'-'+CONVERT(VARCHAR(8),SO.order_ext)+','+CONVERT(VARCHAR(8),SO.order_line)+' contains a recurse build plan',
					'Build #'+@sub_no	-- message
					+' contains part number '+@part_no+' causing a build plan loop',
					SO.sched_order_id	-- sched_order_id
				FROM    dbo.sched_order SO
				WHERE   SO.sched_id = @sched_id
				AND	SO.part_no = @asm_no

				-- Clear #recurse table to exit
				DELETE	#recurse
				END
			ELSE
				-- Add child parts to the list
				INSERT	#recurse(part_no)
				SELECT	WP.part_no
				FROM	dbo.what_part WP
				WHERE	WP.asm_no = @sub_no
			END

		-- Get first item
		SELECT	@recurse_id=MAX(R.recurse_id)
		FROM	#recurse R
		END

	-- Get next part to check
	SELECT	@asm_no=MIN(L.part_no)
	FROM	#list L
	WHERE	L.part_no > @asm_no
	END

-- Clean up temp table
DROP TABLE #recurse
DROP TABLE #list

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_analyze_schedule_recursion] TO [public]
GO
