SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[cvo_create_allocation_temp_table_data_sp] @order_no INT, @ext INT
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @where1 VARCHAR(255)

	-- Clear out temporary tables
	DELETE FROM #so_allocation_detail_view
	DELETE FROM #so_alloc_management
	DELETE FROM #so_pre_allocation_table
	DELETE FROM #temp_sia_working_tbl
	DELETE FROM #top_level_parts
	DELETE FROM #so_alloc_management_Header
	DELETE FROM #so_allocation_detail_view_Detail
	DELETE FROM #so_alloc_err

	SET @where1 = ' AND orders.cust_code = CVO_armaster_all.customer_code and CVO_armaster_all.address_type NOT IN (9,1) AND orders.order_no = *order_no* AND orders.ext = *ext* '

	SET @where1 = REPLACE(@where1,'*order_no*',CAST(@order_no AS VARCHAR))
	SET @where1 = REPLACE(@where1,'*ext*',CAST(@ext AS VARCHAR))

	EXEC tdc_plw_so_alloc_management_sp '', 'Default', @where1 , '', '', '', 'ORDER BY  order_no ASC, order_ext ASC', 0, 0,0,'ALL', 'AUTO_ALLOC', 0
END 
GO
GRANT EXECUTE ON  [dbo].[cvo_create_allocation_temp_table_data_sp] TO [public]
GO
