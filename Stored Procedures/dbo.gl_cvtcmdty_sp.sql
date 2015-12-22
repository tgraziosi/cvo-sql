SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

                                                    CREATE PROC [dbo].[gl_cvtcmdty_sp]  @item_code varchar(30), 
 @qty_item float,  @unit_code varchar(10),  @rpt_ctry_code varchar(3),  @rpt_flag smallint OUTPUT, 
 @cmdty_code varchar(8) OUTPUT,  @orig_ctry_code varchar(3) OUTPUT,  @weight_flag smallint OUTPUT, 
 @weight_value float OUTPUT,  @supp_unit_flag smallint OUTPUT,  @supp_unit_value float OUTPUT 
AS BEGIN DECLARE  @weight_nat float,  @supp_nat float,  @weight_uom varchar(10), 
 @supp_uom varchar(10),  @return_code int     SELECT @rpt_flag = 1, @cmdty_code = '', @orig_ctry_code = '', 
 @weight_flag = 0, @weight_value = 0.0, @supp_unit_flag = 0, @supp_unit_value = 0.0 
 SELECT @unit_code = ISNULL(@unit_code, ''), @qty_item = ISNULL(@qty_item, 0.0)   

	IF (SELECT count(a.name) FROM sysobjects a, syscolumns b 
		WHERE a.id = b.id AND a.name = "inv_master"
		AND b.name IN ("cmdty_code", "country_code") ) > 0
		SELECT @cmdty_code = ISNULL(cmdty_code, ''), @orig_ctry_code = ISNULL(country_code, ''),
			@weight_nat = ISNULL(weight_ea, 0.0), @supp_nat = ISNULL(cubic_feet, 0.0)
		FROM inv_master
		WHERE part_no = @item_code


  IF @cmdty_code = ''  SELECT @cmdty_code = ISNULL(def_cmdty_code, '') FROM gl_glctry WHERE country_code = @rpt_ctry_code 
 SELECT @cmdty_code = cmdty_code, @rpt_flag = rpt_flag_int,  @weight_flag = weight_flag, @supp_unit_flag = supp_unit_flag, 
 @weight_uom = weight_uom, @supp_uom = supp_uom  FROM gl_cmdty  WHERE cmdty_code = @cmdty_code 
 IF @@rowcount <> 1 RETURN 8116  IF @rpt_flag = 1  BEGIN     IF @weight_flag = 1 
 BEGIN  EXEC @return_code = gl_ivcvtqty_sp  @item_code, @unit_code, @weight_uom, @qty_item, @weight_value OUTPUT 
 IF @return_code <> 0 SELECT @weight_value = ISNULL(@weight_nat * @qty_item, 0)  END 
    IF @supp_unit_flag = 1  BEGIN  EXEC @return_code = gl_ivcvtqty_sp  @item_code, @unit_code, @supp_uom, @qty_item, @supp_unit_value OUTPUT 
 IF @return_code <> 0 SELECT @supp_unit_value = ISNULL(@supp_nat * @qty_item, 0) 
 END  END  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_cvtcmdty_sp] TO [public]
GO
