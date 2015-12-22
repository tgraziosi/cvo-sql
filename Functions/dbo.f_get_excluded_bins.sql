SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[f_get_excluded_bins](@type int) -- Type = 0 for list and 1 for sum of qty, 2 for just bins, 3 just bins from config setting, 4 for sum of qty (just bins from config setting) 
RETURNS @rettab table (location varchar(10), part_no varchar(30), bins varchar(12), qty decimal(20,8))
AS
BEGIN
	-- START v1.6
	/*
	-- Declarations
	DECLARE @config_str		varchar(255)


	-- Get tdc_config setting
	SELECT @config_str = ISNULL(value_str,'') FROM dbo.tdc_config (NOLOCK) WHERE [function] = 'INV_EXCLUDED_BINS'
	*/
	-- END v1.6

	-- Parse the results into a table
	-- If type = 0 then return a list
	IF @Type = 0
	BEGIN
		-- START v1.6
		-- v1.9 Start
--		INSERT INTO @rettab 
--		SELECT	
--			location,
--			part_no, 
--			bin_no, 
--			SUM(qty) 
--		FROM	
--			dbo.cvo_lot_bin_stock_exclusions (NOLOCK)
--		GROUP BY 
--			location,
--			part_no, 
--			bin_no
		INSERT INTO @rettab 
		SELECT	
			a.location,
			a.part_no, 
			a.bin_no, 
			SUM(a.qty) - ISNULL(SUM(b.qty),0.0) 
		FROM	
			dbo.cvo_lot_bin_stock_exclusions a (NOLOCK)
		LEFT JOIN (SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) b 
		ON	a.location = b.location
		AND	a.part_no = b.part_no
		AND	a.bin_no = b.bin_no
		GROUP BY 
			a.location,
			a.part_no, 
			a.bin_no
		-- v1.9 End

		/*
		INSERT INTO @rettab 
		SELECT	'001',
				a.part_no, 
				a.bin_no, 
				SUM(a.qty) 
		FROM	dbo.lot_bin_stock a (NOLOCK)
		WHERE	a.bin_no IN (SELECT * FROM fs_cParsing(@config_str))
		AND		a.location = '001'
		GROUP BY a.part_no, a.bin_no
		UNION
		SELECT	'001',
				a.part_no, 
				a.bin_no, 
				SUM(a.qty) 
		FROM	dbo.lot_bin_stock a (NOLOCK)
		JOIN	dbo.cvo_non_allocating_bins b (NOLOCK)-- v1.2
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		WHERE	a.location = '001'
		GROUP BY a.part_no, a.bin_no
		*/
		-- END v1.6
	END
	-- If type = 1 return just a qty for the part
	IF @Type = 1
	BEGIN
		-- START v1.5
		/*
		INSERT INTO @rettab 
		SELECT	'001',
				a.part_no, 
				NULL, 
				SUM(a.qty) 
		FROM	dbo.lot_bin_stock a (NOLOCK)
		JOIN	dbo.cvo_non_allocating_bins b (NOLOCK) -- v1.2
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		WHERE	a.bin_no IN (SELECT * FROM fs_cParsing(@config_str))
		AND		a.location = '001'
		GROUP BY a.part_no
		UNION
		SELECT	'001',
				a.part_no, 
				NULL, 
				SUM(a.qty) 
		FROM	dbo.lot_bin_stock a (NOLOCK)
		JOIN	dbo.cvo_non_allocating_bins b (NOLOCK)-- v1.2
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		WHERE	a.location = '001'
		GROUP BY a.part_no
		*/
		
		-- START v1.6
		-- v1.9 Start
--		INSERT INTO @rettab 
--		SELECT	
--			location,
--			part_no, 
--			NULL, 
--			SUM(qty) 
--		FROM	
--			dbo.cvo_lot_bin_stock_exclusions (NOLOCK)
--		GROUP BY 
--			location,
--			part_no
		INSERT INTO @rettab 
		SELECT	
			a.location,
			a.part_no, 
			NULL, 
			SUM(a.qty) - ISNULL(SUM(b.qty),0.0) 
		FROM	
			dbo.cvo_lot_bin_stock_exclusions a (NOLOCK)
		LEFT JOIN (SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) b 
		ON	a.location = b.location
		AND	a.part_no = b.part_no
		AND	a.bin_no = b.bin_no
		GROUP BY 
			a.location,
			a.part_no
		-- v1.9 End
		/*
		INSERT INTO @rettab 
		SELECT	'001',
				z.part_no, 
				NULL, 
				SUM(z.qty) 
		FROM	(
				SELECT	'001' location,
						a.part_no, 
						NULL bin_no, 
						SUM(a.qty) qty 
				FROM	
						dbo.lot_bin_stock a (NOLOCK)
				WHERE	a.bin_no IN (SELECT * FROM fs_cParsing(@config_str))
				AND		a.location = '001'
				GROUP BY a.part_no
				UNION
				SELECT	'001' location,
						a.part_no, 
						NULL bin_no, 
						SUM(a.qty) qty
				FROM	dbo.lot_bin_stock a (NOLOCK)
				JOIN	dbo.cvo_non_allocating_bins b (NOLOCK)-- v1.2
				ON		a.location = b.location
				AND		a.bin_no = b.bin_no
				WHERE	a.location = '001'
				AND		a.bin_no NOT IN (SELECT * FROM fs_cParsing(@config_str))
				GROUP BY a.part_no) z		
		GROUP BY z.part_no
		*/
		-- END v1.6
	END
	-- If type = 2 return just the bins
	IF @Type = 2
	BEGIN
		-- START v1.6
		INSERT INTO @rettab 
		SELECT 	
			location,
			NULL, 
			bin_no, 
			0
		FROM 
			dbo.cvo_inv_excluded_bins (NOLOCK)
		UNION
		SELECT 	
			location,
			NULL, 
			bin_no, 
			0
		FROM 
			dbo.cvo_non_allocating_bins (NOLOCK)
		
		/*
		INSERT INTO @rettab 
		SELECT	'001',
				NULL, 
				valor, 
				0
		FROM fs_cParsing(@config_str)
		UNION
		SELECT	'001',
				NULL,
				bin_no valor,
				0
		FROM	cvo_non_allocating_bins (NOLOCK) -- v1.2	
		*/
		-- END v1.6	
	END

	-- START v1.3
	-- If type = 3 return just the bins from config setting
	IF @Type = 3
	BEGIN
		-- START v1.6
		INSERT INTO @rettab 
		SELECT DISTINCT	
			location,
			NULL, 
			bin_no, 
			0
		FROM 
			dbo.cvo_inv_excluded_bins (NOLOCK)
		
		/*
		INSERT INTO @rettab 
		SELECT	'001',
				NULL, 
				valor, 
				0
		FROM fs_cParsing(@config_str)	
		*/
		-- END v1.6
	END
	-- END v1.3
	-- START v1.4
	 -- If type = 4 return just a qty for the part (just bins from config setting) 
	 IF @Type = 4  
	 BEGIN  
		-- START v1.6
		-- v1.9 Start
		INSERT INTO @rettab   
		SELECT 
			a.location,  
			a.part_no,   
			NULL,   
			SUM(a.qty) - ISNULL(SUM(b.qty),0.0)   
		FROM	
			dbo.cvo_lot_bin_stock_exclusions a (NOLOCK)
		LEFT JOIN (SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) b 
		ON	a.location = b.location
		AND	a.part_no = b.part_no
		AND	a.bin_no = b.bin_no
		WHERE		
			a.inv_exclude = 1
		GROUP BY	
			a.location,
			a.part_no   

--		SELECT 
--			location,  
--			part_no,   
--			NULL,   
--			SUM(qty)   
--		FROM	
--			dbo.cvo_lot_bin_stock_exclusions (NOLOCK)
--		WHERE		
--			inv_exclude = 1
--		GROUP BY	
--			location,
--			part_no   
		-- v1.9 End
		/*
		INSERT INTO @rettab   
		SELECT '001',  
			a.part_no,   
			NULL,   
			SUM(a.qty)   
		FROM dbo.lot_bin_stock a (NOLOCK)  
		WHERE a.location = '001'
			AND a.bin_no IN (SELECT * FROM fs_cParsing(@config_str)) 
		GROUP BY a.part_no
		*/    
		-- END v1.6
	 END   
	-- END v1.4 
	
	-- v1.7 Start
	IF @Type = 5
	BEGIN
		-- START v1.6
		INSERT INTO @rettab 
		SELECT 	
			a.location,
			a.part_no, 
			NULL, 
			SUM(a.qty)
		FROM 
			dbo.lot_bin_stock a (NOLOCK)
		JOIN
			dbo.tdc_bin_master b (NOLOCK)
		ON
			a.location = b.location
		AND	
			a.bin_no = b.bin_no
		WHERE
			b.usage_type_code = 'QUARANTINE'
		GROUP BY
			a.location, a.part_no
		
	END
	-- v1.7 End

	-- v1.8 Start
	IF @Type = 6
	BEGIN
		INSERT INTO @rettab 
		SELECT 	
			a.location,
			a.part_no, 
			NULL, 
			SUM(a.qty)
		FROM 
			dbo.tdc_soft_alloc_tbl a (NOLOCK)
		WHERE
			a.order_no <> 0
		AND
			a.order_type = 'S'
		GROUP BY
			a.location, a.part_no
		
	END
	-- v1.8 End
	RETURN
END
GO
GRANT REFERENCES ON  [dbo].[f_get_excluded_bins] TO [public]
GO
GRANT SELECT ON  [dbo].[f_get_excluded_bins] TO [public]
GO
