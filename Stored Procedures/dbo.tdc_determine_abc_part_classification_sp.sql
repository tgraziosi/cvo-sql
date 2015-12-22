SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_determine_abc_part_classification_sp]
	@upper_percentage	decimal(20,8),
	@lower_percentage	decimal(20,8),
	@location		varchar(12),
	@start_date		varchar(35),
	@end_date		varchar(35),
	@processing_option	int,
	@part_type		char(5),
	@part_group		varchar(10)

AS

--VARIABLES
DECLARE
	@sum_total		decimal(20,8),
	@sum_total_cost		decimal(20,8),
	@part_no		varchar(30),   --cursor variable
	@percentage		decimal(20,8), --cursor variable
	@class_rank		char(1),       --cursor variable
	@sum_percentage		decimal(20,8), --summation variable to determine classification
	@total_rows		int,
	@a_count		int,
	@b_count		int,
	@start_date_val		datetime,
	@end_date_val		datetime

--FOR DEBUGGING PURPOSES:
-- --INPUTS
-- DECLARE @upper_percentage	decimal(20,8),
-- 	@lower_percentage	decimal(20,8),
-- 	@location		varchar(12),
-- 	@start_date		varchar(20),
-- 	@end_date		varchar(20),
-- 	@processing_option	int,
-- 	@part_type		char(5),
-- 	SELECT 	@upper_percentage = 80,
-- 		@lower_percentage = 45,
-- 		@location = 'Dallas',
-- 		@start_date = getdate() -10000, 
-- 		@end_date = getdate(),
-- 		@processing_option = 0,
-- 		@part_type = '<ALL>'

TRUNCATE TABLE #inv_class_parts
TRUNCATE TABLE #inv_class_temp_parts

--@processing_option = 0
--Quantity on Hand
IF @processing_option = 0
BEGIN
	SELECT @sum_total = SUM(b.qty)
	  FROM 	inv_list a (NOLOCK),
		lot_bin_stock b (NOLOCK),
		inv_master c (NOLOCK)
	WHERE a.location = @location
	  AND a.part_no = b.part_no
	  AND a.location = b.location
	  AND a.status = (CASE WHEN @part_type = '<ALL>' THEN a.status ELSE @part_type END)
	  AND a.status IN ('H', 'M', 'P', 'Q')
	  AND a.part_no = c.part_no
	  AND c.category = (CASE WHEN @part_group = '<ALL>' THEN c.category ELSE @part_group END)

	INSERT INTO #inv_class_parts (part_no, percentage, old_rank, new_rank)
		SELECT a.part_no, CASE WHEN @sum_total <> 0 THEN (SUM(b.qty)/@sum_total)*100 ELSE 0 END,  a.rank_class  [old_rank_class], ''
		  FROM 	inv_list a (NOLOCK),
			lot_bin_stock b (NOLOCK),
			inv_master c (NOLOCK)
		WHERE a.location = @location
		  AND a.part_no = b.part_no
		  AND a.location = b.location
		  AND a.status = (CASE WHEN @part_type = '<ALL>' THEN a.status ELSE @part_type END)
		  AND a.status IN ('H', 'M', 'P', 'Q')
		  AND a.part_no = c.part_no
		  AND c.category = (CASE WHEN @part_group = '<ALL>' THEN c.category ELSE @part_group END)
		GROUP BY a.part_no, a.rank_class
		ORDER BY 2 DESC
END

--@processing_option = 1
--Quantity on Hand * Unit Cost
IF @processing_option = 1
BEGIN
	SELECT @sum_total = SUM(b.qty*a.std_cost)
	  FROM 	inv_list a (NOLOCK),
		lot_bin_stock b (NOLOCK),
		inv_master c (NOLOCK)
	WHERE a.location = @location
	  AND a.part_no = b.part_no
	  AND a.location = b.location
	  AND a.status = (CASE WHEN @part_type = '<ALL>' THEN a.status ELSE @part_type END)
	  AND a.status IN ('H', 'M', 'P', 'Q')
	  AND a.part_no = c.part_no
	  AND c.category = (CASE WHEN @part_group = '<ALL>' THEN c.category ELSE @part_group END)

	INSERT INTO #inv_class_parts (part_no, percentage, old_rank, new_rank)
		SELECT a.part_no, CASE WHEN @sum_total <> 0 THEN (SUM(a.qty*b.std_cost)/@sum_total)*100 ELSE 0 END, b.rank_class , ''
		  FROM 	lot_bin_stock a (NOLOCK),
			inv_list b (NOLOCK),
			inv_master c (NOLOCK)
		WHERE a.location = @location
		  AND a.part_no = b.part_no
		  AND a.location = b.location
		  AND b.status = (CASE WHEN @part_type = '<ALL>' THEN b.status ELSE @part_type END)
		  AND b.status IN ('H', 'M', 'P', 'Q')
		  AND a.part_no = c.part_no
		  AND c.category = (CASE WHEN @part_group = '<ALL>' THEN c.category ELSE @part_group END)
		GROUP BY a.part_no, b.rank_class
		ORDER BY 2 DESC
END

--@processing_option = 2
--Number of Picks - Qty Picked Percentage
IF @processing_option = 2	
BEGIN
	SELECT @sum_total = SUM(c.qty)
	  FROM 	inv_list a (NOLOCK),
		lot_bin_stock b (NOLOCK),
		lot_bin_ship c (NOLOCK),
		inv_master d (NOLOCK)
	WHERE a.location = @location
	  AND a.part_no = b.part_no
	  AND a.location = b.location
	  AND a.part_no = c.part_no
	  AND a.location = c.location
	  AND CONVERT(varchar(20), c.date_tran, 101) BETWEEN CONVERT(varchar(20), CAST(@start_date AS DATETIME), 101) AND CONVERT(varchar(20), CAST(@end_date AS DATETIME), 101)
	  AND a.status = (CASE WHEN @part_type = '<ALL>' THEN a.status ELSE @part_type END)
	  AND a.status IN ('H', 'M', 'P', 'Q')
	  AND a.part_no = d.part_no
	  AND d.category = (CASE WHEN @part_group = '<ALL>' THEN d.category ELSE @part_group END)

	INSERT INTO #inv_class_parts (part_no, percentage, old_rank, new_rank)	
		SELECT a.part_no, CASE WHEN @sum_total <> 0 THEN (SUM(c.qty)/@sum_total)*100 ELSE 0 END, a.rank_class, ''
		  FROM 	inv_list a (NOLOCK),
			lot_bin_stock b (NOLOCK),
			lot_bin_ship c (NOLOCK),
			inv_master d (NOLOCK)
		WHERE a.location = @location
		  AND a.part_no = b.part_no
		  AND a.location = b.location
		  AND a.part_no = c.part_no
		  AND a.location = c.location
		  AND CONVERT(varchar(20), c.date_tran, 101) BETWEEN CONVERT(varchar(20), CAST(@start_date AS DATETIME), 101) AND CONVERT(varchar(20), CAST(@end_date AS DATETIME), 101)
		  AND a.status = (CASE WHEN @part_type = '<ALL>' THEN a.status ELSE @part_type END)
		  AND a.status IN ('H', 'M', 'P', 'Q')
		  AND a.part_no = d.part_no
		  AND d.category = (CASE WHEN @part_group = '<ALL>' THEN d.category ELSE @part_group END)
		GROUP BY a.part_no, a.rank_class
		ORDER BY 2 DESC	
END
--@processing_option = 3
--Number of Picks - Number of transactions
IF @processing_option = 3
BEGIN
	SELECT @sum_total = COUNT(*)--Number of transactions total based on the date ranges
	  FROM 	inv_list a (NOLOCK),
		lot_bin_stock b (NOLOCK),
		lot_bin_ship c (NOLOCK),
		inv_master d (NOLOCK)
	WHERE a.location = @location
	  AND a.part_no = b.part_no
	  AND a.location = b.location
	  AND a.part_no = c.part_no
	  AND a.location = c.location
	  AND CONVERT(varchar(20), c.date_tran, 101) BETWEEN CONVERT(varchar(20), CAST(@start_date AS DATETIME), 101) AND CONVERT(varchar(20), CAST(@end_date AS DATETIME), 101)
	  AND a.status = (CASE WHEN @part_type = '<ALL>' THEN a.status ELSE @part_type END)
	  AND a.status IN ('H', 'M', 'P', 'Q')
	  AND a.part_no = d.part_no
	  AND d.category = (CASE WHEN @part_group = '<ALL>' THEN d.category ELSE @part_group END)

	INSERT INTO #inv_class_parts (part_no, percentage, old_rank, new_rank)
		SELECT a.part_no, CASE WHEN @sum_total <> 0 THEN (COUNT(c.part_no)/@sum_total)*100 ELSE 0 END, a.rank_class, ''
		  FROM 	inv_list a (NOLOCK),
			lot_bin_stock b (NOLOCK),
			lot_bin_ship c (NOLOCK),
			inv_master d (NOLOCK)
		WHERE a.location = @location
		  AND a.part_no = b.part_no
		  AND a.location = b.location
		  AND a.part_no = c.part_no
		  AND a.location = c.location
		  AND CONVERT(varchar(20), c.date_tran, 101) BETWEEN CONVERT(varchar(20), CAST(@start_date AS DATETIME), 101) AND CONVERT(varchar(20), CAST(@end_date AS DATETIME), 101)
		  AND a.status = (CASE WHEN @part_type = '<ALL>' THEN a.status ELSE @part_type END)
		  AND a.status IN ('H', 'M', 'P', 'Q')
		  AND a.part_no = d.part_no
		  AND d.category = (CASE WHEN @part_group = '<ALL>' THEN d.category ELSE @part_group END)
		GROUP BY a.part_no, a.rank_class
		ORDER BY 2 DESC	
END

--@processing_option = 4
--Order Demand
IF @processing_option = 4
BEGIN

	SELECT @start_date_val = CONVERT(datetime, @start_date)
	SELECT @end_date_val = CONVERT(datetime, @end_date)

	SELECT @sum_total = ISNULL(SUM(b.ordered), 0)
	  FROM 	orders a (NOLOCK),
		ord_list b (NOLOCK),
		inv_master c (NOLOCK),
		inv_list d (NOLOCK)
	WHERE a.status < 'R'
	  AND a.order_no = b.order_no
	  AND a.ext = b.order_ext
	  AND b.part_no = c.part_no
	  AND b.location = @location
	  AND b.part_type <> 'M'
	  AND d.part_no = b.part_no
	  AND d.location = b.location
	  AND d.status = (CASE WHEN @part_type = '<ALL>' THEN d.status ELSE @part_type END)
	  AND d.status IN ('H', 'M', 'P', 'Q')
	  AND CONVERT(varchar(20), a.sch_ship_date, 101) BETWEEN CONVERT(varchar(20), @start_date_val, 101) AND CONVERT(varchar(20), @end_date_val, 101)
	  AND c.category = (CASE WHEN @part_group = '<ALL>' THEN c.category ELSE @part_group END)
-- sp_help orders
-- sch_ship_date

	INSERT INTO #inv_class_parts (part_no, percentage, old_rank, new_rank)
		SELECT b.part_no, CASE WHEN @sum_total <> 0 THEN (SUM(b.ordered)/@sum_total)*100 ELSE 0 END, d.rank_class, ''
		  FROM 	orders a (NOLOCK),
			ord_list b (NOLOCK),
			inv_master c (NOLOCK),
			inv_list d (NOLOCK)
		WHERE a.status < 'R'
		  AND a.order_no = b.order_no
		  AND a.ext = b.order_ext
		  AND b.part_no = c.part_no
		  AND b.location = @location
		  AND b.part_type <> 'M'
		  AND d.part_no = b.part_no
		  AND d.location = b.location
		  AND d.status = (CASE WHEN @part_type = '<ALL>' THEN d.status ELSE @part_type END)
		  AND d.status IN ('H', 'M', 'P', 'Q')
		  AND CONVERT(varchar(20), a.sch_ship_date, 101) BETWEEN CONVERT(varchar(20), @start_date_val, 101) AND CONVERT(varchar(20), @end_date_val, 101)
		  AND c.category = (CASE WHEN @part_group = '<ALL>' THEN c.category ELSE @part_group END)
		GROUP BY b.part_no, d.rank_class
		ORDER BY 2 DESC
END

SELECT @total_rows = MAX(rowid) FROM #inv_class_parts

--We will ALWAYS have at least 1 "A" part
--Assign A parts
SELECT @a_count = @total_rows * ((100 - @upper_percentage)/100)
IF @a_count = 0
	SELECT @a_count = 1

INSERT INTO #inv_class_temp_parts (part_no, old_rank, percentage, new_rank)
	SELECT part_no, old_rank, percentage, 'A' 
	  FROM #inv_class_parts
	WHERE rowid <= @a_count

DELETE FROM #inv_class_parts WHERE rowid <= @a_count

--Assign B parts
SELECT @b_count = @total_rows * ((@upper_percentage - @lower_percentage)/100)
IF @b_count = 0
BEGIN	--WE make sure that we assign a "B" part in this case, so we don't have an "A" part and "C" part with no "B" parts
	IF (@total_rows - @a_count) > 0
	BEGIN
		SELECT @b_count = 1
	END
END

INSERT INTO #inv_class_temp_parts (part_no, old_rank, percentage, new_rank)
	SELECT part_no, old_rank, percentage, 'B' 
	  FROM #inv_class_parts
	WHERE rowid <= @a_count + @b_count

DELETE FROM #inv_class_parts WHERE rowid <= @a_count + @b_count

--Assign C parts
INSERT INTO #inv_class_temp_parts (part_no, old_rank, percentage, new_rank)
	SELECT part_no, old_rank, percentage, 'C' 
	  FROM #inv_class_parts

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_determine_abc_part_classification_sp] TO [public]
GO
