SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 15/10/2012 - Issue #937 - Fix issue where the user can delete a line that is allcoated or picked
-- v1.1 CT 12/11/2012 - If updating or deleting a line, unallocate the transfer first  

CREATE PROCEDURE [dbo].[scm_pb_set_dw_xfer_list_sp]  
@typ char(1), @xfer_no integer, @line_no integer, @from_loc varchar(10)  
, @to_loc varchar(10), @part_no varchar(30), @description varchar(255)  
, @time_entered datetime, @ordered decimal(20,8), @shipped decimal(20,8)  
, @note varchar(255), @status char(1), @cost decimal(20,8), @com_flag char(1)  
, @who_entered varchar(20), @temp_cost decimal(20,8), @uom varchar(2)  
, @conv_factor decimal(20,8), @std_cost decimal(20,8), @from_bin varchar(12)  
, @to_bin varchar(12), @lot_ser varchar(25), @date_expires datetime  
, @lb_tracking char(1), @labor decimal(20,8), @direct_dolrs decimal(20,8)  
, @ovhd_dolrs decimal(20,8), @util_dolrs decimal(20,8)  
, @inv_master_allow_fractions integer, @display_line integer  
, @inv_master_cubic_feet decimal(20,8), @inv_master_weight_ea decimal(20,8)  
, @inv_master_serial_flag integer, @c_tdc_status varchar(35)  
, @back_ord_flag integer, @timestamp varchar(20)  
 AS  
BEGIN  
set nocount on  
DECLARE @ts timestamp  
exec adm_varchar_to_ts_sp @timestamp, @ts output  

-- v1.0 Start
DECLARE @message varchar(255)
IF @typ IN ('U','D')
BEGIN
	IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @xfer_no AND line_no = @line_no AND order_type = 'T')
	BEGIN
		-- START v1.1
		-- Unallocate it
		EXEC cvo_plw_xfer_unallocate_sp @xfer_no, @who_entered -- v1.1

		-- If still allocated raise error
		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @xfer_no AND line_no = @line_no AND order_type = 'T')
		BEGIN
			ROLLBACK TRAN 
			SET @message = 'Transfer line ' + CAST(@line_no AS varchar(10)) + ' must be unallocated.' 
			RAISERROR 832115 @message  
			RETURN  
		END
		-- END v1.1 
	END
	IF (@shipped <> 0)
	BEGIN
		ROLLBACK TRAN 
		SET @message = 'Transfer line ' + CAST(@line_no AS varchar(10)) + ' already picked.' 
		RAISERROR 832115 @message  
		RETURN   
	END
END
-- v1.0 End

if @typ = 'I'  
begin  
Insert into xfer_list (xfer_list.xfer_no, xfer_list.line_no, xfer_list.from_loc, xfer_list.to_loc  
, xfer_list.part_no, xfer_list.description, xfer_list.time_entered  
, xfer_list.ordered, xfer_list.shipped, xfer_list.comment, xfer_list.status  
, xfer_list.cost, xfer_list.com_flag, xfer_list.who_entered, xfer_list.temp_cost  
, xfer_list.uom, xfer_list.conv_factor, xfer_list.std_cost, xfer_list.from_bin  
, xfer_list.to_bin, xfer_list.lot_ser, xfer_list.date_expires  
, xfer_list.lb_tracking, xfer_list.labor, xfer_list.direct_dolrs  
, xfer_list.ovhd_dolrs, xfer_list.util_dolrs, xfer_list.display_line  
, xfer_list.back_ord_flag  
)  
values (@xfer_no, @line_no, @from_loc, @to_loc, @part_no, @description, @time_entered  
, @ordered, @shipped, @note, @status, @cost, @com_flag, @who_entered, @temp_cost  
, @uom, @conv_factor, @std_cost, @from_bin, @to_bin, @lot_ser, @date_expires  
, @lb_tracking, @labor, @direct_dolrs, @ovhd_dolrs, @util_dolrs  
, isnull(@display_line,(0)), @back_ord_flag  
)  
end  
if @typ = 'U'  
begin  

update xfer_list set  
xfer_list.from_loc= @from_loc, xfer_list.to_loc= @to_loc  
, xfer_list.part_no= @part_no, xfer_list.description= @description  
, xfer_list.time_entered= @time_entered, xfer_list.ordered= @ordered  
, xfer_list.shipped= @shipped, xfer_list.comment= @note  
, xfer_list.status= @status, xfer_list.cost= @cost  
, xfer_list.com_flag= @com_flag, xfer_list.who_entered= @who_entered  
, xfer_list.temp_cost= @temp_cost, xfer_list.uom= @uom  
, xfer_list.conv_factor= @conv_factor, xfer_list.std_cost= @std_cost  
, xfer_list.from_bin= @from_bin, xfer_list.to_bin= @to_bin  
, xfer_list.lot_ser= @lot_ser, xfer_list.date_expires= @date_expires  
, xfer_list.lb_tracking= @lb_tracking, xfer_list.labor= @labor  
, xfer_list.direct_dolrs= @direct_dolrs, xfer_list.ovhd_dolrs= @ovhd_dolrs  
, xfer_list.util_dolrs= @util_dolrs, xfer_list.display_line= @display_line  
, xfer_list.back_ord_flag= @back_ord_flag  
where xfer_list.xfer_no= @xfer_no and xfer_list.line_no= @line_no  
 and xfer_list.timestamp= @ts   
if @@rowcount = 0  
begin  
  rollback tran  
  RAISERROR 832115 'Row changed between retrieve and update'  
  RETURN   
end  
end  
if @typ = 'D'  
begin
 
delete from xfer_list  
where xfer_list.xfer_no= @xfer_no and xfer_list.line_no= @line_no  
  
if @@rowcount = 0  
begin  
  rollback tran  
  RAISERROR 832115 'Error Deleting Row'  
  RETURN   
end  
end  
  
  
return  
end  
  
GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_xfer_list_sp] TO [public]
GO
