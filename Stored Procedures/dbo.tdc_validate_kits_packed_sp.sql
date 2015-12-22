SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_validate_kits_packed_sp]
	@stage_no varchar(11),
	@order_no int, 
	@order_ext int,
	@err_msg varchar(100) OUTPUT
AS

DECLARE @kit_part_no varchar(30), @language varchar(10)

SELECT @kit_part_no = ''
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

SELECT @kit_part_no = kit_part_no 
FROM tdc_ord_list_kit  
WHERE order_no = @order_no 
AND order_ext = @order_ext 
AND kit_part_no NOT IN 
	( SELECT part_no from tdc_carton_detail_tx  
	WHERE order_no = @order_no AND order_ext = @order_ext)

if rtrim(ltrim(@kit_part_no)) <> ''
BEGIN
	-- 'Part ' + @kit_part_no + ' required for a Custom Kit is not packed on stage ' + @stage_no
	SELECT @err_msg = err_msg + @kit_part_no FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_validate_kits_packed_sp' AND err_no = -101 AND language = @language 
	SELECT @err_msg = @err_msg + err_msg + @stage_no FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_validate_kits_packed_sp' AND err_no = -102 AND language = @language
	
	return -1
END
return 0
GO
GRANT EXECUTE ON  [dbo].[tdc_validate_kits_packed_sp] TO [public]
GO
