SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[scm_pb_set_dw_xfer_rcv_list_sp]
@typ char(1), @xfer_no integer, @line_no integer, @from_loc varchar(10)
, @to_loc varchar(10), @part_no varchar(30), @description varchar(255)
, @time_entered datetime, @ordered decimal(20,8), @shipped decimal(20,8)
, @note varchar(255), @status char(1), @cost decimal(20,8), @com_flag char(1)
, @who_entered varchar(20), @temp_cost decimal(20,8), @uom varchar(2)
, @conv_factor decimal(20,8), @std_cost decimal(20,8), @from_bin varchar(12)
, @to_bin varchar(12), @lot_ser varchar(25), @date_expires datetime
, @lb_tracking char(1), @labor decimal(20,8), @direct_dolrs decimal(20,8)
, @ovhd_dolrs decimal(20,8), @util_dolrs decimal(20,8), @display_line integer
, @inventory_lb_tracking char(1), @inventory_allow_fractions integer
, @inventory_bin_no varchar(12), @xfer_list_amt_variance decimal(20,8)
, @xfer_list_qty_rcvd decimal(20,8), @xfer_list_ship decimal(20,8)
, @back_ord_flag integer, @timestamp varchar(20)
 AS
BEGIN
set nocount on
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
  rollback tran
  RAISERROR 832115 'You cannot insert a new transfer line from the transfer receive screen'
  RETURN 
end
if @typ = 'U'
begin
update xfer_list set
xfer_list.from_loc= @from_loc, xfer_list.to_loc= @to_loc
, xfer_list.part_no= @part_no, xfer_list.description= @description
, xfer_list.time_entered= @time_entered, xfer_list.ordered= @ordered
, xfer_list.comment= @note, xfer_list.status= @status, xfer_list.cost= @cost
, xfer_list.com_flag= @com_flag, xfer_list.who_entered= @who_entered
, xfer_list.temp_cost= @temp_cost, xfer_list.uom= @uom
, xfer_list.conv_factor= @conv_factor, xfer_list.std_cost= @std_cost
, xfer_list.from_bin= @from_bin, xfer_list.to_bin= @to_bin
, xfer_list.lot_ser= @lot_ser, xfer_list.date_expires= @date_expires
, xfer_list.lb_tracking= @lb_tracking, xfer_list.labor= @labor
, xfer_list.direct_dolrs= @direct_dolrs, xfer_list.ovhd_dolrs= @ovhd_dolrs
, xfer_list.util_dolrs= @util_dolrs, xfer_list.display_line= @display_line
, xfer_list.amt_variance= @xfer_list_amt_variance
, xfer_list.qty_rcvd= @xfer_list_qty_rcvd
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
end

GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_xfer_rcv_list_sp] TO [public]
GO
