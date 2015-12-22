SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_labor_template_price]
	@cust_code 	varchar(10),
	@ship_to 	varchar(10),
	@contract_name 	varchar(20),
	@location	varchar(10),
	@template_name	varchar(30),
	@begin_date 	datetime,
	@end_date	datetime,
	@total_price 	varchar(20) OUTPUT
AS

DECLARE @tran_id 		int,
	@category 		varchar(50),
	@fee 			decimal(20, 8),
	@price 			decimal(20, 8),
	@qty 			decimal(20, 8),
	@expert 		char(1),
	@part_filter_reqd 	char(1),
	@subtran 		varchar(10),
	@table_name 		varchar(100),
	@select_value 		varchar(35),
	@filter_type 		char(1),
	@part_no_name 		varchar(30),
	@part_filter 		varchar(1000),
	@SQL_QUERY 		varchar(5000)

SET @price = 0

SELECT TOP 1 @filter_type = type 
  FROM tdc_3pl_assigned_parts (NOLOCK)
 WHERE cust_code = @cust_code
   AND ship_to = @ship_to
   AND contract_name = @contract_name
   
--TEMP TABLE USED FOR STORING ALL PRICES
IF OBJECT_ID('tempdb..#prices') IS NOT NULL 
	DROP TABLE #prices
CREATE TABLE #prices 
(
	qty decimal(20, 8) NOT NULL, 
	fee decimal(20, 8)
)

DECLARE tran_cursor CURSOR FOR 
	SELECT a.category, a.tran_id, a.fee, b.part_filter_reqd
	  FROM  tdc_3pl_labor_assigned_transactions a(NOLOCK),
		tdc_3pl_labor_avail_transactions    b (NOLOCK)
	 WHERE a.location = @location
	   AND a.template_name = @template_name
	   AND a.category = b.category
	   AND a.tran_id = b.tran_id
	 ORDER BY a.category, a.tran_id
OPEN tran_cursor
FETCH NEXT FROM tran_cursor INTO @category, @tran_id, @fee, @part_filter_reqd
WHILE @@FETCH_STATUS = 0
BEGIN
	--SET default value for @part_no_name when used in dynamic sql statements
	SELECT @part_no_name = 'part_no'

	--DETERMINE IF THE TRANSACTION IS EXPERT OR NOVICE
	SELECT @expert = expert 
	  FROM tdc_3pl_labor_avail_transactions 
	WHERE category = @category 
	  AND tran_id = @tran_id

	IF @category = 'RECEIPT_TRANSACTIONS'
	BEGIN
		SELECT @subtran = CASE (@tran_id % 6)
			WHEN 1 THEN 'PORECV'
			WHEN 2 THEN 'XFRECV'
			WHEN 3 THEN 'CRRETN'
			WHEN 4 THEN 'POALTREC'
			WHEN 5 THEN 'AUTOXFRECV'
			ELSE 'ADHOCRECV'
		END
		
		SELECT @table_name = 'tdc_3pl_receipts_log'

		IF (@tran_id < 13)
			SELECT @select_value = 'COUNT(*)'
		ELSE
			SELECT @select_value = 'ISNULL(SUM(qty), 0)'

	END
	ELSE IF @category = 'WO_CLOSE'
	BEGIN
		SELECT @subtran = 'WOCLOSE'

		SELECT @table_name = 'tdc_3pl_wo_close_log'

		SELECT @select_value = 'COUNT(*)'
	END
	ELSE IF @category = 'BIN_ACTIVITY'
	BEGIN
		SELECT @subtran = CASE (@tran_id % 5)
			WHEN 1 THEN 'BN2BN'
			WHEN 2 THEN 'QUARAN'
			WHEN 3 THEN 'WH2WH'
			WHEN 4 THEN 'QBN2BN'
			ELSE 'PUTAWAY'
		END

		SELECT @table_name = 'tdc_3pl_bin_activity_log'

		IF (@tran_id < 11)
			SELECT @select_value = 'COUNT(*)'
		ELSE
			SELECT @select_value = 'ISNULL(SUM(qty), 0)'
	END
	ELSE IF @category = 'PICK_TRANSACTIONS'
	BEGIN
		SELECT @subtran = CASE (@tran_id % 10)
			WHEN 1 THEN 'STDOPICK'
			WHEN 2 THEN 'UNPICKORD'
			WHEN 3 THEN 'STDXPICK'
			WHEN 4 THEN 'UNPICKXFR'
			WHEN 5 THEN 'QSTDOPICK'
			WHEN 6 THEN 'QXFERPICK'
			WHEN 7 THEN 'PKGBLD'
			WHEN 8 THEN 'WOPICKER'
			WHEN 9 THEN 'WOPCK'
			ELSE 'WOUNPCK'
		END
			
		SELECT @table_name = 'tdc_3pl_pick_log'

		IF (@tran_id < 21)
			SELECT @select_value = 'COUNT(*)'
		ELSE
			SELECT @select_value = 'ISNULL(SUM(qty), 0)'
	END
	ELSE IF @category = 'ITEM_RECLASS'
	BEGIN
		--DIFFERENT PART OPTIONS
		IF @tran_id < 5
	 		SELECT @part_no_name = 'orig_part_no'
		ELSE
	 		SELECT @part_no_name = 'reclass_part_no'

		SELECT @subtran = 'IRECLASS'

		SELECT @table_name = 'tdc_3pl_item_reclass_log'

		IF (@tran_id < 3) OR ((@tran_id >= 5) OR (@tran_id <= 6))
			SELECT @select_value = 'COUNT(*)'
		ELSE
			SELECT @select_value = 'ISNULL(SUM(qty), 0)'
	END
	ELSE IF @category = 'SHIP_LOG'
	BEGIN
		SELECT @subtran = CASE (@tran_id % 2)
			WHEN 1 THEN 'STDOSHVF'
			ELSE 'STDXSHVF'
		END

		SELECT @table_name = 'tdc_3pl_ship_log'

		SELECT @select_value = 'COUNT(*)'
	END
	ELSE IF @category = 'RETURN_TO_VENDOR'
	BEGIN
		SELECT @subtran = 'RETNVD'

		SELECT @table_name = 'tdc_3pl_rtv_log'

		IF (@tran_id < 3)
			SELECT @select_value = 'COUNT(*)'
		ELSE
			SELECT @select_value = 'ISNULL(SUM(qty), 0)'
	END
	ELSE IF @category = 'ADHOC_ADJUSTMENTS'
	BEGIN
		SELECT @subtran = 'ADHOC'

		SELECT @table_name = 'tdc_3pl_issues_log'

		IF (@tran_id < 3)
			SELECT @select_value = 'COUNT(*)'
		ELSE
			SELECT @select_value = 'ISNULL(SUM(qty), 0)'
	END
	ELSE IF @category = 'WO_CONSUMP_OUTPUT_REPORTING'
	BEGIN
		SELECT @subtran = CASE (@tran_id % 4)
			WHEN 1 THEN 'OUTPUT'
			WHEN 2 THEN 'USAGE'
			WHEN 3 THEN 'SCRAP'
			ELSE 'PSCRAP'
		END

		SELECT @table_name = 'tdc_3pl_wo_prod_output_log'

		IF (@tran_id < 9)
			SELECT @select_value = 'COUNT(*)'
		ELSE
			SELECT @select_value = 'ISNULL(SUM(qty), 0)'
	END
	ELSE IF @category = 'WO_RESOURCE_REPORTING'
	BEGIN
		SELECT @subtran = 'RESRCE'

		SELECT @table_name = 'tdc_3pl_wo_resource_log'

		IF (@tran_id < 3)
			SELECT @select_value = 'COUNT(*)'
		ELSE
			SELECT @select_value = 'ISNULL(SUM(qty), 0)'
	END
	ELSE IF @category = 'QC_RELEASES'
	BEGIN
		SELECT @subtran = CASE (@tran_id % 3)
			WHEN 1 THEN 'ADHQCREL'
			WHEN 2 THEN 'POADHQCREL'
			ELSE 'WOQCREL'
		END

		SELECT @table_name = 'tdc_3pl_qc_release_log'

		IF (@tran_id < 7)
			SELECT @select_value = 'COUNT(*)'
		ELSE
		BEGIN
			IF (@tran_id < 13)
				SELECT @select_value = 'ISNULL(SUM(qc_qty), 0)'
			ELSE
				SELECT @select_value = 'ISNULL(SUM(reject_qty), 0)'
		END
	END
	ELSE IF @category = 'ADHOCQC'
	BEGIN
		SELECT @subtran = 'ADHOCQC', @table_name = 'tdc_3pl_issues_log'
		IF (@tran_id < 3)
			SELECT @select_value = 'COUNT(*)'
		ELSE
			SELECT @select_value = 'ISNULL(SUM(qty), 0)'
	END
		
	IF @part_filter_reqd = 'Y'
	BEGIN
		--APPLY PART FILTER
		SELECT @part_filter = CASE @filter_type
			WHEN 'P' THEN  ' AND ' + @part_no_name + ' IN (SELECT filter_value ' +
							' FROM tdc_3pl_assigned_parts (NOLOCK) ' +
				      		' WHERE cust_code = ' + CHAR(39) + @cust_code + CHAR(39) +
				           	' AND ship_to = ' + CHAR(39) + @ship_to + CHAR(39) +
				           	' AND contract_name = ' + CHAR(39) + @contract_name + CHAR(39) + ')'
			WHEN 'G' THEN ' AND ' + @part_no_name + ' IN (SELECT b.part_no ' +
							' FROM tdc_3pl_assigned_parts a (NOLOCK), ' +
								' inv_master b (NOLOCK) ' +
							' WHERE cust_code = ' + CHAR(39) + @cust_code + CHAR(39) +
				     	     		' AND ship_to = ' + CHAR(39) + @ship_to + CHAR(39) +
							' AND contract_name = ' + CHAR(39) + @contract_name + CHAR(39) +
							' AND a.filter_value = b.category)'
			WHEN 'R' THEN ' AND ' + @part_no_name + ' IN (SELECT b.part_no ' +
							' FROM tdc_3pl_assigned_parts a (NOLOCK), ' +
								' inv_master b (NOLOCK) ' +
				      			' WHERE cust_code = ' + CHAR(39) + @cust_code+ CHAR(39) +
							' AND ship_to = ' + CHAR(39) + @ship_to+ CHAR(39) +
							' AND contract_name = ' + CHAR(39) + @contract_name + CHAR(39) +
							' AND a.filter_value = b.type_code)'
			
			WHEN 'L' THEN ' AND location IN (SELECT filter_value ' +
							' FROM tdc_3pl_assigned_parts (NOLOCK) '+
							' WHERE cust_code = ' + CHAR(39) + @cust_code + CHAR(39) +
							' AND ship_to = ' + CHAR(39) + @ship_to + CHAR(39) +
							' AND contract_name = ' + CHAR(39) + @contract_name + CHAR(39) + ')'
			ELSE 'AND ' + CHAR(39) + CHAR(39) + ' IS NULL' --forces empty set
			END
	END
	ELSE
	BEGIN
		SELECT @part_filter = ''
	END

	SELECT @SQL_QUERY = 	
		'INSERT INTO #prices SELECT ' + @select_value + ', ' +CAST( @fee AS varchar(20))+ ' FROM ' + @table_name + ' (NOLOCK) ' +
		' WHERE tran_date BETWEEN ' + CHAR(39) + CAST(@begin_date AS varchar(25)) + CHAR(39) + ' AND ' + 
				CHAR(39) + CAST(@end_date AS varchar(25)) + CHAR(39) +
		' AND trans = ' + CHAR(39) + @subtran + CHAR(39) +
		' AND expert = ' + CHAR(39) + @expert + CHAR(39) +
		' AND location = ' + CHAR(39) + @location + CHAR(39) + @part_filter
	EXEC (@SQL_QUERY)
 
	FETCH NEXT FROM tran_cursor INTO @category, @tran_id, @fee, @part_filter_reqd
END

CLOSE tran_cursor
DEALLOCATE tran_cursor			
SELECT @price = ROUND(SUM(qty * fee),2) FROM #prices
SELECT @total_price = CAST(@price AS varchar(20))
RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_labor_template_price] TO [public]
GO
