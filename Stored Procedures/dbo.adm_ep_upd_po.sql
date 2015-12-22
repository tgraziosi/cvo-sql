SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create procedure [dbo].[adm_ep_upd_po]  @po_no varchar(16), @approval_ind int, @transmit_ind int, @transmit_date datetime, 
				@proc_po_no varchar(20)
as
declare @rc int
select @rc = 1

if @approval_ind = 0
begin
  update purchase_all
  set status = case when isnull(approval_status,'') = 'P' then 'C' else status end, 
    void = case when isnull(approval_status,'') = 'P' then 'V' else 'N' end, 
    void_date = case when isnull(approval_status,'') = 'P' then getdate() else NULL end, 
    void_who = case when isnull(approval_status,'') = 'P' then user_name() else NULL end, 
    approval_status = case when isnull(approval_status,'') = 'P' then 'F' else approval_status end,
    eprocurement_last_recv_date = getdate(),
    printed = case when @transmit_ind = 1 and isnull(etransmit_status,'') = 'P' then 'Y' else printed end,
    etransmit_status = case when @transmit_ind = 1 and isnull(etransmit_status,'') = 'P' then 'T' else etransmit_status end,
    etransmit_date = case @transmit_ind when 1 then @transmit_date else etransmit_date end,
	proc_po_no = @proc_po_no
  where po_no = @po_no
end
if @approval_ind = 1
begin
  update purchase_all
  set approval_status = NULL,
    eprocurement_last_recv_date = getdate(),
    status = case when status = 'H' then 'O' else status end,
    hold_reason = NULL,
    printed = case when @transmit_ind = 1 and isnull(etransmit_status,'') = 'P' then 'Y' else printed end,
    etransmit_status = case when @transmit_ind = 1 and isnull(etransmit_status,'') = 'P' then 'T' else etransmit_status end,
    etransmit_date = case @transmit_ind when 1 then @transmit_date else etransmit_date end,
	proc_po_no = @proc_po_no
  where po_no = @po_no
end

return @rc

GO
GRANT EXECUTE ON  [dbo].[adm_ep_upd_po] TO [public]
GO
