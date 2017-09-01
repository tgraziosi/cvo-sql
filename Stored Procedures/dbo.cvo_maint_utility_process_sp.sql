SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_maint_utility_process_sp] @process int = 0
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @row_id				int,
			@last_row_id		int,
			@usage_type			varchar(10),
			@group_code			varchar(10),
			@part_no			varchar(30),
			@bin_no				varchar(20),
			@fill_qty_max		decimal(20,8),
			@bin_repl_min		decimal(20,8),
			@bin_repl_max		decimal(20,8),
			@bin_repl_qty		decimal(20,8),
			@rec_type			int, -- -1 not processed, 0 Error, > 0 updates ok
			@message			varchar(255),
			@rec_action			varchar(30),
			@max_seq			int,
			@location			varchar(10) -- v1.1

	-- PROCESSING
	IF (@process = 0) -- Validation
	BEGIN

		UPDATE	a
		SET		rec_type = 0,
				[error_message] = 'ERROR: Invalid bin'
		FROM	#MaintUtil_File a
		LEFT JOIN tdc_bin_master b (NOLOCK)
		ON		a.bin_no = b.bin_no
		AND		a.location = b.location -- v1.1
		WHERE	b.location IS NULL -- v1.1
		AND		(b.status = 'A' OR b.status IS NULL)
		AND		b.bin_no IS NULL

		UPDATE	a
		SET		usage_type_code = b.usage_type_code,
				group_code = b.group_code
		FROM	#MaintUtil_File a
		JOIN	tdc_bin_master b (NOLOCK)
		ON		a.bin_no = b.bin_no
		AND		a.location = b.location -- v1.1
		WHERE	b.status = 'A' -- v1.1
		AND		a.rec_type = -1
		
		UPDATE	#MaintUtil_File
		SET		rec_type = 0,
				[error_message] = 'ERROR: Invalid usage type / bin group combination'
		WHERE	usage_type_code = 'REPLENISH'
		AND		group_code NOT IN ('PICKAREA','RESERVE')
		AND		rec_type = -1

		UPDATE	#MaintUtil_File
		SET		rec_type = 0,
				[error_message] = 'ERROR: Invalid usage type / bin group combination'
		WHERE	usage_type_code = 'OPEN'
		AND		group_code <> ('HIGHBAY')
		AND		rec_type = -1

		UPDATE	#MaintUtil_File
		SET		rec_type = 0,
				[error_message] = 'ERROR: Invalid usage type'
		WHERE	(ISNULL(usage_type_code,'') = '' OR usage_type_code NOT IN ('REPLENISH','OPEN'))
		AND		rec_type = -1
		
		UPDATE	#MaintUtil_File
		SET		rec_type = 0,
				[error_message] = 'ERROR: Invalid bin group'
		WHERE	(ISNULL(group_code,'') = '' OR group_code NOT IN ('PICKAREA','RESERVE','HIGHBAY'))
		AND		rec_type = -1

		UPDATE	a
		SET		rec_type = 0,
				[error_message] = 'ERROR: Invalid part number'
		FROM	#MaintUtil_File a
		LEFT JOIN inv_list b (NOLOCK)
		ON		a.sku = b.part_no
		AND		a.location = b.location -- v1.1
		WHERE	b.location IS NULL -- v1.1
		AND		b.part_no IS NULL
		AND		a.rec_type = -1		

		UPDATE	#MaintUtil_File
		SET		rec_type = 0,
				[error_message] = 'ERROR: Invalid data for FILL QTY MAX'
		WHERE	usage_type_code = 'REPLENISH'
		AND		group_code = ('PICKAREA')
		AND		fill_qty_max IS NULL
		AND		rec_type = -1

		UPDATE	#MaintUtil_File
		SET		rec_type = 0,
				[error_message] = 'ERROR: Invalid data'
		WHERE	usage_type_code = 'REPLENISH'
		AND		(fill_qty_max IS NULL OR bin_repl_min IS NULL OR bin_repl_max IS NULL OR bin_repl_qty IS NULL)
		AND		rec_type = -1

		UPDATE	#MaintUtil_File
		SET		rec_type = 0,
				[error_message] = 'ERROR: Invalid data'
		WHERE	usage_type_code = 'OPEN'
		AND		group_code = 'HIGHBAY'
		AND		(fill_qty_max IS NULL OR bin_repl_min IS NULL)
		AND		rec_type = -1

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@part_no = sku,
				@bin_no = bin_no,
				@usage_type = usage_type_code,
				@group_code = group_code,
				@fill_qty_max = fill_qty_max,
				@bin_repl_min = bin_repl_min,
				@bin_repl_max = bin_repl_max,
				@bin_repl_qty = bin_repl_qty,
				@location = location -- v1.1
		FROM	#MaintUtil_File
		WHERE	row_id > @last_row_id
		AND		rec_type = -1
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			SET @message = ''
			SET @rec_action = ''

			IF (@usage_type = 'REPLENISH' AND @group_code = 'PICKAREA')
			BEGIN
				IF (@fill_qty_max > 0)
				BEGIN
					IF EXISTS( SELECT 1 FROM tdc_bin_part_qty (NOLOCK) WHERE location = @location AND part_no = @part_no AND bin_no = @bin_no) -- v1.1
					BEGIN
						SET @message = @message + 'REMOVING tdc_bin_part_qty record; '
						SET @rec_action = @rec_action + 'A'
					END
					
					IF EXISTS( SELECT 1 FROM tdc_bin_part_qty (NOLOCK) WHERE location = @location AND part_no = @part_no AND [primary] = 'Y' AND bin_no <> @bin_no) -- v1.1
					BEGIN
						SET @message = @message + 'REMOVING additional primary record; '
						SET @rec_action = @rec_action + 'B'
					END
					
					SET @message = @message + 'ADDING new primary record; '
					SET @rec_action = @rec_action + 'C'
				END
				ELSE
				BEGIN
					SET @message = @message + 'REMOVING tdc_bin_part_qty record; '
					SET @rec_action = @rec_action + 'A'
				END
				IF (@bin_repl_max > 0)
				BEGIN
					IF EXISTS( SELECT 1 FROM tdc_bin_replenishment (NOLOCK) WHERE location = @location AND part_no = @part_no AND bin_no = @bin_no) -- v1.1
					BEGIN
						SET @message = @message + 'REMOVING tdc_bin_replenishment record; '
						SET @rec_action = @rec_action + 'D'
					END
					SET @message = @message + 'ADDING new replenishment record; '
					SET @rec_action = @rec_action + 'E'
				END
				ELSE
				BEGIN
					SET @message = @message + 'REMOVING replenishment record; '
					SET @rec_action = @rec_action + 'D'
				END
			END
			
			IF (@usage_type = 'REPLENISH' AND @group_code = 'RESERVE')
			OR ( @usage_type = 'OPEN' AND @group_code = 'HIGHBAY' ) -- tag 2/2017
			BEGIN
				IF (@fill_qty_max > 0)
				BEGIN
					IF EXISTS( SELECT 1 FROM tdc_bin_part_qty (NOLOCK) WHERE location = @location AND part_no = @part_no AND bin_no = @bin_no) -- v1.1
					BEGIN
						SET @message = @message + 'REMOVING tdc_bin_part_qty record; '
						SET @rec_action = @rec_action + 'A'
					END
					SET @message = @message + 'ADDING new secondary record; '
					SET @rec_action = @rec_action + 'F'
				END
				ELSE
				BEGIN
					SET @message = @message + 'REMOVING tdc_bin_part_qty record; '
					SET @rec_action = @rec_action + 'A'
				END
				IF (@bin_repl_max > 0)
				BEGIN
					IF EXISTS( SELECT 1 FROM tdc_bin_replenishment (NOLOCK) WHERE location = @location AND part_no = @part_no AND bin_no = @bin_no) -- v1.1
					BEGIN
						SET @message = @message + 'REMOVING tdc_bin_replenishment record; '
						SET @rec_action = @rec_action + 'D'
					END
					SET @message = @message + 'ADDING new replenishment record; '
					SET @rec_action = @rec_action + 'E'
				END
				ELSE
				BEGIN
					SET @message = @message + 'REMOVING replenishment record; '
					SET @rec_action = @rec_action + 'D'
				END
			END

			/*
			IF (@usage_type = 'OPEN' AND @group_code = 'HIGHBAY')
			BEGIN
				IF (@fill_qty_max > 0)
				BEGIN
					IF EXISTS( SELECT 1 FROM tdc_bin_part_qty (NOLOCK) WHERE location = '001' AND part_no = @part_no AND bin_no = @bin_no)
					BEGIN
						SET @message = @message + 'REMOVING tdc_bin_part_qty record; '
						SET @rec_action = @rec_action + 'A'
					END
					SET @message = @message + 'ADDING new secondary record; '
					SET @rec_action = @rec_action + 'F'
				END
				ELSE
				BEGIN
					SET @message = @message + 'REMOVING tdc_bin_part_qty record; '
					SET @rec_action = @rec_action + 'A'
				END
				IF (@bin_repl_max > 0)
				BEGIN
					IF EXISTS( SELECT 1 FROM cvo_bin_replenishment_tbl (NOLOCK) WHERE part_no = @part_no AND bin_no = @bin_no)
					BEGIN
						SET @message = @message + 'REMOVING cvo_bin_replenishment_tbl record; '
						SET @rec_action = @rec_action + 'G'
					END
					SET @message = @message + 'ADDING new cvo replenishment record; '
					SET @rec_action = @rec_action + 'H'
				END
				ELSE
				BEGIN
					SET @message = @message + 'REMOVING cvo_bin_replenishment_tbl record; '
					SET @rec_action = @rec_action + 'G'
				END
			END
			*/

			UPDATE	#MaintUtil_File
			SET		[error_message] = @message,
					rec_action = @rec_action,
					rec_type = 1
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@part_no = sku,
					@bin_no = bin_no,
					@usage_type = usage_type_code,
					@group_code = group_code,
					@fill_qty_max = fill_qty_max,
					@bin_repl_min = bin_repl_min,
					@bin_repl_max = bin_repl_max,
					@bin_repl_qty = bin_repl_qty,
					@location = location -- v1.1
			FROM	#MaintUtil_File
			WHERE	row_id > @last_row_id
			AND		rec_type = -1
			ORDER BY row_id ASC
		END
			
		UPDATE	#MaintUtil_File
		SET		[error_message] = 'ERROR: Unknown Error',
				rec_type = 0
		WHERE	rec_type = -1

		UPDATE	#MaintUtil_File
		SET		sel_flag = 0
		WHERE	rec_type <> 1
		
	END

	IF (@process = 1) -- Process records
	BEGIN

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@part_no = sku,
				@bin_no = bin_no,
				@usage_type = usage_type_code,
				@group_code = group_code,
				@fill_qty_max = fill_qty_max,
				@bin_repl_min = bin_repl_min,
				@bin_repl_max = bin_repl_max,
				@bin_repl_qty = bin_repl_qty,
				@rec_action = rec_action,
				@location = location -- v1.1
		FROM	#MaintUtil_File
		WHERE	row_id > @last_row_id
		AND		rec_type = 1
		AND		sel_flag = -1
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			IF (CHARINDEX('A',@rec_action) > 0)
			BEGIN
				DELETE	tdc_bin_part_qty
				WHERE	location = @location -- v1.1
				AND		part_no = @part_no
				AND		bin_no = @bin_no
			END
			IF (CHARINDEX('B',@rec_action) > 0)
			BEGIN
				DELETE	tdc_bin_part_qty
				WHERE	location = @location -- v1.1
				AND		part_no = @part_no
				AND		[primary] = 'Y'
			END
			IF (CHARINDEX('C',@rec_action) > 0)
			BEGIN				
				INSERT	tdc_bin_part_qty
				VALUES  (@location, @part_no, @bin_no, @fill_qty_max, 'Y', 0) -- v1.1

			-- tag - 8/24/2017
				UPDATE tdc_bin_master SET maximum_level = @fill_qty_max WHERE 
					location = @location AND bin_no = @bin_no AND maximum_level <> @fill_qty_max
			END
			IF (CHARINDEX('D',@rec_action) > 0)
			BEGIN				
				DELETE	tdc_bin_replenishment
				WHERE	location = @location -- v1.1
				AND		bin_no = @bin_no
				AND		part_no = @part_no
			END
			IF (CHARINDEX('E',@rec_action) > 0)
			BEGIN				
				INSERT	tdc_bin_replenishment
				VALUES	(@location, @bin_no, @part_no, @bin_repl_min, @bin_repl_max, @bin_repl_qty, GETDATE(), 'Upload', 0) -- v1.1
			END
			IF (CHARINDEX('F',@rec_action) > 0)
			BEGIN			
				SET @max_seq = 0

				SELECT	@max_seq = MAX(seq_no)
				FROM	tdc_bin_part_qty (NOLOCK)
				WHERE	location = @location -- v1.1
				AND		part_no = @part_no

				IF (ISNULL(@max_seq,0) = 0)
					SET @max_seq = 1
				ELSE
					SET @max_seq = @max_seq + 1
					
				INSERT	tdc_bin_part_qty
				VALUES  (@location, @part_no, @bin_no, @fill_qty_max, 'N', @max_seq) -- v1.1
			END
			IF (CHARINDEX('G',@rec_action) > 0)
			BEGIN				
				DELETE	cvo_bin_replenishment_tbl
				WHERE	part_no = @part_no
				AND		bin_no = @bin_no
			END
			IF (CHARINDEX('H',@rec_action) > 0)
			BEGIN				
				INSERT	cvo_bin_replenishment_tbl (part_no, bin_no, min_qty, rep_qty)
				VALUES	(@part_no, @bin_no, @bin_repl_min, 0)
			END

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@part_no = sku,
					@bin_no = bin_no,
					@usage_type = usage_type_code,
					@group_code = group_code,
					@fill_qty_max = fill_qty_max,
					@bin_repl_min = bin_repl_min,
					@bin_repl_max = bin_repl_max,
					@bin_repl_qty = bin_repl_qty,
					@rec_action = rec_action,
					@location = location -- v1.1
			FROM	#MaintUtil_File
			WHERE	row_id > @last_row_id
			AND		rec_type = 1
			AND		sel_flag = -1
			ORDER BY row_id ASC
		END

		TRUNCATE TABLE #MaintUtil_File

	END
	
END

GO
GRANT EXECUTE ON  [dbo].[cvo_maint_utility_process_sp] TO [public]
GO
