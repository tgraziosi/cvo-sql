SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_bin_view_template_statistics_sp]
	@template_id		int,
	@show_all_templates	char(1),
	@userid			varchar(50),
	@err_msg		varchar(255) OUTPUT
AS
	DECLARE	@language		 	varchar(10),
		@location			varchar(10),
		@rowid			 	int,
		@summaryrowid			int,
		@template_name			varchar(30),
		@template_desc			varchar(50),
		@percent_full			decimal(20,8),
		@percent_alloc			decimal(20,8),
		@maximum_level			decimal(20,8),
		@total_parts_in_bins		decimal(20,8),
		@sum_of_maximum_levels		decimal(20,8),
		@sum_of_allocated_qty		decimal(20,8),
		@summary_bin_count		decimal(20,8),
		@bin_count			int,
		@bins_used_in_calculation	int,
		@bin_usage_type		 	varchar(10),
		@bin_used_ratio		 	decimal(20,8),
		@allocated_by_type_ratio 	decimal(20,8)

	SELECT @language = ISNULL(language, 'us_english') FROM tdc_sec (NOLOCK) WHERE userid = @userid

	IF NOT EXISTS(SELECT TOP 1 * FROM tdc_graphical_bin_template (NOLOCK))
	BEGIN   --'No Graphical Bin View templates exist. Please create a template and try again.'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE language = @language AND module = 'GBV' AND trans = 'GBV_GEN' AND  err_no = 19
		RETURN -1
	END
	-- 	SELECT * FROM #tdc_gbv_template_summary
	-- 	SELECT * FROM #tdc_gbv_template_bin_summary

	TRUNCATE TABLE #tdc_gbv_template_summary
	TRUNCATE TABLE #tdc_gbv_template_bin_summary

	IF @show_all_templates = 'Y'
	BEGIN
		INSERT INTO #tdc_gbv_template_summary (	template_id,  template_name, template_desc, location, percent_full, 
							percent_alloc, bin_count, bins_used_in_calculation)
			SELECT template_id, template_name, template_desc, location, 0, 0, 0, 0 FROM tdc_graphical_bin_template		
	END
	ELSE
	BEGIN
		IF NOT EXISTS(SELECT * FROM tdc_graphical_bin_template (NOLOCK) WHERE template_id = @template_id)
		BEGIN   --'Template ID does not exist.'
			SELECT err_msg FROM tdc_lookup_error (NOLOCK) WHERE language = @language AND module = 'GBV' AND trans = 'GBV_GEN' AND  err_no = 9
			RETURN -2
		END

		INSERT INTO #tdc_gbv_template_summary (	template_id,  template_name, template_desc, percent_full, 
							percent_alloc, bin_count, bins_used_in_calculation)
			SELECT template_id, template_name, template_desc, 0, 0, 0, 0 FROM tdc_graphical_bin_template WHERE template_id = @template_id
	END

	DECLARE template_cursor CURSOR FOR
		SELECT 	rowid, template_id,  template_name, template_desc, 
			percent_full, percent_alloc, bin_count, bins_used_in_calculation 
		FROM  #tdc_gbv_template_summary
	OPEN template_cursor
	FETCH NEXT FROM template_cursor INTO @rowid, @template_id,  @template_name, @template_desc, 
			@percent_full, @percent_alloc, @bin_count, @bins_used_in_calculation
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT 	@location = location FROM tdc_graphical_bin_template WHERE template_id = @template_id
		SELECT	@percent_full = 0,
			@percent_alloc = 0,
			@bin_count = 0,
			@bins_used_in_calculation = 0

		--GET TOTAL NUMBER OF BINS
		SELECT @bin_count = ISNULL(COUNT(*) , 0)
		FROM	tdc_graphical_bin_store bs (NOLOCK),
			tdc_bin_master bm (NOLOCK)
		WHERE 	bs.template_id = @template_id
		  AND   bs.bin_no = bm.bin_no
		  AND   bm.location = @location

		--GET TOTAL NUMBER OF BINS USED IN CALCULATIONS
		SELECT @bins_used_in_calculation = @bin_count - ISNULL(COUNT(*) , 0) 
		FROM	tdc_graphical_bin_store bs (NOLOCK),
			tdc_bin_master bm (NOLOCK)
		WHERE 	 bs.template_id = @template_id
		 AND 	bs.bin_no = bm.bin_no
		 AND    bm.maximum_level = 0
		 AND    bm.location = @location

		--TOTAL PARTS IN BIN
		SELECT @total_parts_in_bins = ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) 
		WHERE bin_no IN (
			SELECT bs.bin_no
			FROM 	tdc_graphical_bin_store bs (NOLOCK),
				tdc_bin_master bm (NOLOCK)
			WHERE bs.template_id = @template_id
			  AND bs.bin_no = bm.bin_no
			  AND bm.location = @location
			  AND bm.maximum_level <> 0)

		--GET THE PERCENTAGE OF BINS THAT ARE FULL IN THIS TEMPLATE
		SELECT @sum_of_maximum_levels = ISNULL(SUM(maximum_level), 0)
		FROM 	tdc_graphical_bin_store bs (NOLOCK),
			tdc_bin_master bm (NOLOCK)
		WHERE bs.template_id = @template_id
		  AND bs.bin_no = bm.bin_no
		  AND bm.location = @location
		  AND bm.maximum_level <> 0

		IF @sum_of_maximum_levels <> 0
		  SELECT @percent_full = (@total_parts_in_bins/@sum_of_maximum_levels) * 100
		ELSE
		  SELECT @percent_full = 0

		--GET THE ALLOCATED PERCENTAGES FOR ALL OF THE BINS THAT ARE IN THIS TEMPLATE
		SELECT @sum_of_allocated_qty = ISNULL(SUM(qty), 0) FROM tdc_soft_alloc_tbl (NOLOCK) 
		WHERE bin_no IN (
			SELECT bs.bin_no
			FROM 	tdc_graphical_bin_store bs (NOLOCK),
				tdc_bin_master bm (NOLOCK)
			WHERE bs.template_id = @template_id
			  AND bs.bin_no = bm.bin_no
			  AND bm.location = @location
			  AND bm.maximum_level <> 0)	

		IF @total_parts_in_bins <> 0
		  SELECT @percent_alloc = (@sum_of_allocated_qty/@total_parts_in_bins) * 100
		ELSE
		  SELECT @percent_alloc = 0

		--UPDATE HEADER INFORMATION
		UPDATE #tdc_gbv_template_summary 
			SET	percent_full = @percent_full,
				percent_alloc = @percent_alloc, 
				bin_count = @bin_count, 
				bins_used_in_calculation = @bins_used_in_calculation
			WHERE rowid = @rowid

		--INSERT DETAIL RECORDS
		INSERT INTO #tdc_gbv_template_bin_summary 
			(template_id, bin_usage_type, bin_count, bin_used_ratio, allocated_by_type_ratio)
			SELECT 	@template_id, usage_type_code, Count(*) [bin_count], 0, 0
			FROM 	tdc_graphical_bin_store bs (NOLOCK),
				tdc_bin_master bm (NOLOCK)
			WHERE bs.template_id = @template_id
			  AND bs.bin_no = bm.bin_no
			  AND bm.location = @location
			GROUP BY usage_type_code

		DECLARE bin_summary_cursor CURSOR FOR
			SELECT rowid, bin_usage_type, bin_count
			  FROM #tdc_gbv_template_bin_summary
			WHERE template_id = @template_id
		OPEN bin_summary_cursor
		FETCH NEXT FROM bin_summary_cursor 
			INTO @summaryrowid, @bin_usage_type , @summary_bin_count 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			--TOTAL PARTS IN BIN
			SELECT @total_parts_in_bins = ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) 
			WHERE bin_no IN (
				SELECT bs.bin_no
				FROM 	tdc_graphical_bin_store bs (NOLOCK),
					tdc_bin_master bm (NOLOCK)
				WHERE bs.template_id = @template_id
				  AND bs.bin_no = bm.bin_no
				  AND bm.location = @location
				  AND bm.maximum_level <> 0
				  AND bm.usage_type_code = @bin_usage_type)

			--GET THE PERCENTAGE OF BINS THAT ARE FULL IN THIS TEMPLATE
			SELECT @sum_of_maximum_levels = ISNULL(SUM(maximum_level), 0)
			FROM 	tdc_graphical_bin_store bs (NOLOCK),
				tdc_bin_master bm (NOLOCK)
			WHERE bs.template_id = @template_id
			  AND bs.bin_no = bm.bin_no
			  AND bm.location = @location
			  AND bm.maximum_level <> 0
			  AND bm.usage_type_code = @bin_usage_type
	
			IF @sum_of_maximum_levels <> 0
			  SELECT @bin_used_ratio = (@total_parts_in_bins/@sum_of_maximum_levels) * 100
			ELSE
			  SELECT @bin_used_ratio = 0
	
			--GET THE ALLOCATED PERCENTAGES FOR ALL OF THE BINS THAT ARE IN THIS TEMPLATE
			SELECT @sum_of_allocated_qty = ISNULL(SUM(qty), 0) FROM tdc_soft_alloc_tbl (NOLOCK) 
			WHERE bin_no IN (
				SELECT bs.bin_no
				FROM 	tdc_graphical_bin_store bs (NOLOCK),
					tdc_bin_master bm (NOLOCK)
				WHERE bs.template_id = @template_id
				  AND bs.bin_no = bm.bin_no
				  AND bm.location = @location
				  AND bm.maximum_level <> 0
				  AND bm.usage_type_code = @bin_usage_type)	
	
			IF @total_parts_in_bins <> 0
			  SELECT @allocated_by_type_ratio = (@sum_of_allocated_qty/@total_parts_in_bins) * 100
			ELSE
			  SELECT @allocated_by_type_ratio = 0

			UPDATE #tdc_gbv_template_bin_summary 
				SET 	bin_used_ratio = @bin_used_ratio, 
					allocated_by_type_ratio = @allocated_by_type_ratio
					WHERE template_id = @template_id
					  AND rowid = @summaryrowid

			FETCH NEXT FROM bin_summary_cursor 
				INTO @summaryrowid, @bin_usage_type , @summary_bin_count
		END
		CLOSE bin_summary_cursor
		DEALLOCATE bin_summary_cursor

		FETCH NEXT FROM template_cursor INTO @rowid, @template_id,  @template_name, @template_desc, 
				@percent_full, @percent_alloc, @bin_count, @bins_used_in_calculation
	END
	CLOSE template_cursor
	DEALLOCATE template_cursor
	--DELETE TEMPLATES WHICH HAVE NO BINS
	--DELETE FROM #tdc_gbv_template_summary WHERE bin_count = 0
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_get_bin_view_template_statistics_sp] TO [public]
GO
