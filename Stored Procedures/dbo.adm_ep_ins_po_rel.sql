SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
              
              
              
              
              
              
              
              
                                                              
              
              
              
CREATE procedure [dbo].[adm_ep_ins_po_rel]              
@proc_po_no  varchar(20), --  REQUIRED              
@po_line  integer, --   REQUIRED (must relate to PO line on pur_list for PO)              
@release_date datetime, --  REQUIRED              
@quantity  decimal(20,8), -- REQUIRED              
@confirm_date datetime = NULL, -- default NULL              
@confirmed  char(1) = NULL,  -- default NULL              
@due_date  datetime = NULL  -- default release_date              
as              
set nocount on              
              
declare @po_no varchar(16), @po_key int              
declare @part_no varchar(30), @location varchar(10),              
@part_type char(1), @lb_tracking char(1),              
@conv_factor decimal(20,8), @status char(1)              
              
if @proc_po_no is NULL return -10              
if @po_line is NULL return -20              
if @release_date is NULL return -30              
if @quantity is NULL return -40              
              
select @po_no = po_no,              
@po_key = po_key              
from purchase_all (nolock)              
where proc_po_no = @proc_po_no and status in ('O','H')              
              
if @@rowcount = 0  return -12              
              
            
select @part_no = part_no,              
@location = receiving_loc,              
@part_type = type,              
@lb_tracking = lb_tracking,              
@conv_factor = conv_factor,              
@status = status              
from pur_list (nolock)              
where po_no = @po_no and line = @po_line and status in ('O','H')              
              
if @@rowcount = 0  return -21              
              
if exists (select 1 from releases (nolock) where po_no = @po_no              
  and po_line = @po_line and release_date = @release_date)              
begin              
  return 100              
end              
else              
begin              
  if @due_date is NULL select @due_date = @release_date              
  if @confirm_date is NULL select @confirm_date = @release_date              
  if @confirmed is NULL select @confirmed = 'N'              
              
  begin tran              
  insert releases (po_no,part_no,location,part_type,release_date,quantity,received,              
    status,confirm_date,confirmed,lb_tracking,conv_factor,prev_qty,po_key,due_date,              
    ord_line,po_line,receipt_batch_no)              
  select @po_no,@part_no,@location,@part_type,@release_date,@quantity,0,              
    @status,@confirm_date,@confirmed,@lb_tracking,@conv_factor,0,@po_key,@due_date,              
  NULL,@po_line,NULL              
              
  if @@error <> 0              
  begin              
    rollback tran              
    return -300              
  end              
              
  commit tran              
end              
              
return 1 
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_po_rel] TO [public]
GO
