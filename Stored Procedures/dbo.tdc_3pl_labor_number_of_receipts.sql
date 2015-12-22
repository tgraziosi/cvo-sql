SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_3pl_labor_number_of_receipts]
	@cust_code     	varchar(10),
	@ship_to       	varchar(10),
	@contract_name 	varchar(20),
	@location	varchar(10),
	@template_name	varchar(30),
	@begin_date	datetime,
	@end_date	datetime,
	@transaction	varchar(10),
	@expert		char(1)
AS

DECLARE @trans			varchar(100), 
	@select_clause		varchar(6000),
	@part_filter_clause	varchar(3000),
	@filter_by_part		varchar(3000),
	@filter_by_group	varchar(3000),
	@filter_by_res_type	varchar(3000),
	@filter_by_location	varchar(3000),
	@fee			decimal(20, 8),
	@price			decimal(20, 8),
	@qty			decimal(20, 8),
	@part_filter		char(1)

SELECT @qty		= 0,
       @part_filter     = ''

SET @filter_by_part =      ' AND part_no IN (SELECT part_no 
				 	       FROM tdc_3pl_assigned_parts (NOLOCK) 
		      			      WHERE cust_code     = ' + CHAR(39) + @cust_code     + CHAR(39) +
		           ' 		        AND ship_to       = ' + CHAR(39) + @ship_to       + CHAR(39) +
		           '                    AND contract_name = ' + CHAR(39) + @contract_name + CHAR(39) + ')'

SET @filter_by_group =     ' AND part_no IN (SELECT b.part_no 
				    	       FROM tdc_3pl_assigned_parts a (NOLOCK),
					            inv_master	      b (NOLOCK)
		      	    		      WHERE cust_code     = ' + CHAR(39) + @cust_code     + CHAR(39) +
		          ' 		        AND ship_to       = ' + CHAR(39) + @ship_to       + CHAR(39) +
		          '                     AND contract_name = ' + CHAR(39) + @contract_name + CHAR(39) +
		          '		        AND a.part_no     = b.category)'

SET @filter_by_res_type = ' AND part_no IN (SELECT b.part_no 
					      FROM tdc_3pl_assigned_parts a (NOLOCK),
					           inv_master	      b (NOLOCK)
		      			     WHERE cust_code     = ' + CHAR(39) + @cust_code     + CHAR(39) +
		          ' 		       AND ship_to       = ' + CHAR(39) + @ship_to       + CHAR(39) +
		          '                    AND contract_name = ' + CHAR(39) + @contract_name + CHAR(39) +
		          '		       AND a.part_no     = b.type_code)'

SET @filter_by_location = ' AND location IN (SELECT part_no 
					       FROM tdc_3pl_assigned_parts (NOLOCK) 
		      			      WHERE cust_code     = ' + CHAR(39) + @cust_code     + CHAR(39) +
		          ' 		        AND ship_to       = ' + CHAR(39) + @ship_to       + CHAR(39) +
		          '                     AND contract_name = ' + CHAR(39) + @contract_name + CHAR(39) + ')'

SELECT @trans = CASE @transaction 
			WHEN 'PO'      THEN 'PORECV'
			WHEN 'CR'      THEN 'CRRETN'
			WHEN 'XFER'    THEN 'XFRECV'
			WHEN 'AlterPO' THEN 'POALTREC'
		END

SELECT @part_filter = type 
  FROM tdc_3pl_assigned_parts (NOLOCK)
 WHERE cust_code     = @cust_code
   AND ship_to       = @ship_to
   AND contract_name = @contract_name

SELECT @part_filter_clause = CASE @part_filter
				WHEN 'P' THEN  @filter_by_part
       				WHEN 'G' THEN  @filter_by_group
       				WHEN 'R' THEN  @filter_by_res_type
       				WHEN 'L' THEN  @filter_by_location
				ELSE ''
			     END

SELECT @select_clause = 'SELECT COUNT(*) 
			   FROM tdc_3pl_receipts_log (NOLOCK)
			  WHERE tran_date BETWEEN ' + CHAR(39) + CAST(@begin_date AS varchar(25)) + CHAR(39) + ' AND ' + 
						      CHAR(39) + CAST(@end_date   AS varchar(25)) + CHAR(39) +
			'   AND trans    = ' + CHAR(39) + @trans    + CHAR(39) +
			'   AND expert   = ' + CHAR(39) + @expert   + CHAR(39) +
			'   AND location = ' + CHAR(39) + @location + CHAR(39) +
			@part_filter_clause
   
IF OBJECT_ID('tempdb..#qty') IS NOT NULL DROP TABLE #qty
CREATE TABLE #qty (qty decimal(20, 8) NOT NULL)

EXEC ('INSERT INTO #qty ' + @select_clause)
 
SELECT @qty = qty FROM #qty

RETURN @qty
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_labor_number_of_receipts] TO [public]
GO
