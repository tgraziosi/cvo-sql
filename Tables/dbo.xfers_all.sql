CREATE TABLE [dbo].[xfers_all]
(
[timestamp] [timestamp] NOT NULL,
[xfer_no] [int] NOT NULL,
[from_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[req_ship_date] [datetime] NOT NULL,
[sch_ship_date] [datetime] NULL,
[date_shipped] [datetime] NULL,
[date_entered] [datetime] NOT NULL,
[req_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routing] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[special_instr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight] [decimal] (20, 8) NOT NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[label_no] [int] NULL,
[no_cartons] [int] NULL,
[who_shipped] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_printed] [datetime] NULL,
[who_picked] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_loc_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_loc_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_loc_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_loc_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_loc_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_loc_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[no_pallets] [int] NULL,
[shipper_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipper_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipper_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipper_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipper_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipper_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipper_zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rec_no] [int] NULL,
[who_recvd] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_recvd] [datetime] NULL,
[pick_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_xfers_pick_ctrl_num] DEFAULT (''),
[from_organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[proc_po_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[back_ord_flag] [int] NULL,
[orig_xfer_no] [int] NULL,
[orig_xfer_ext] [int] NULL,
[autopack] [smallint] NULL,
[autoship] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t600delxfers] ON [dbo].[xfers_all] 
 FOR DELETE 
AS
begin
if exists (select * from config where flag='TRIG_DEL_XFER' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 77099, 'You Can Not Delete A XFER!' 
	return
	end
end



declare @tdc_rtn int, @n1 int, @n2 int

SELECT @n1 = 0
SELECT @n2 = min(xfer_no) FROM deleted

WHILE @n1 < @n2
BEGIN

   SELECT @n1 = min(xfer_no) FROM deleted WHERE xfer_no > @n1

   exec @tdc_rtn = tdc_xfer_hdr_change @n1 

   if (@tdc_rtn< 0 )
   begin
      exec adm_raiserror 77900 ,'Invalid Inventory Update From TDC.'
   end

END




GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600insxfers] ON [dbo].[xfers_all] FOR insert AS 
BEGIN

if exists (select 1 from config where flag='TRIG_INS_XFER' and value_str='DISABLE') return

DECLARE @i_xfer_no int, @i_from_loc varchar(10), @i_to_loc varchar(10), @i_req_ship_date datetime,
@i_sch_ship_date datetime, @i_date_shipped datetime, @i_date_entered datetime,
@i_req_no varchar(20), @i_who_entered varchar(20), @i_status char(1), @i_attention varchar(15),
@i_phone varchar(20), @i_routing varchar(20), @i_special_instr varchar(255), @i_fob varchar(10),
@i_freight decimal(20,8), @i_printed char(1), @i_label_no int, @i_no_cartons int,
@i_who_shipped varchar(20), @i_date_printed datetime, @i_who_picked varchar(20),
@i_to_loc_name varchar(40), @i_to_loc_addr1 varchar(40), @i_to_loc_addr2 varchar(40),
@i_to_loc_addr3 varchar(40), @i_to_loc_addr4 varchar(40), @i_to_loc_addr5 varchar(40),
@i_no_pallets int, @i_shipper_no varchar(10), @i_shipper_name varchar(40),
@i_shipper_addr1 varchar(40), @i_shipper_addr2 varchar(40), @i_shipper_city varchar(40),
@i_shipper_state varchar(40), @i_shipper_zip varchar(10), @i_cust_code varchar(10),
@i_freight_type varchar(10), @i_note varchar(255), @i_rec_no int, @i_who_recvd varchar(20),
@i_date_recvd datetime, @i_pick_ctrl_num varchar(32), @i_from_organization_id varchar(30),
@i_to_organization_id varchar(30)

declare @tdc_rtn int, @msg varchar(80)

DECLARE t700insxfer_cursor CURSOR LOCAL STATIC FOR
SELECT i.xfer_no, i.from_loc, i.to_loc, i.req_ship_date, i.sch_ship_date, i.date_shipped,
i.date_entered, i.req_no, i.who_entered, i.status, i.attention, i.phone, i.routing,
i.special_instr, i.fob, i.freight, i.printed, i.label_no, i.no_cartons, i.who_shipped,
i.date_printed, i.who_picked, i.to_loc_name, i.to_loc_addr1, i.to_loc_addr2, i.to_loc_addr3,
i.to_loc_addr4, i.to_loc_addr5, i.no_pallets, i.shipper_no, i.shipper_name, i.shipper_addr1,
i.shipper_addr2, i.shipper_city, i.shipper_state, i.shipper_zip, i.cust_code, i.freight_type,
i.note, i.rec_no, i.who_recvd, i.date_recvd, i.pick_ctrl_num, isnull(i.from_organization_id,''),
isnull(i.to_organization_id,'')
from inserted i

OPEN t700insxfer_cursor

if @@cursor_rows = 0
begin
CLOSE t700insxfer_cursor
DEALLOCATE t700insxfer_cursor
return
end

FETCH NEXT FROM t700insxfer_cursor into
@i_xfer_no, @i_from_loc, @i_to_loc, @i_req_ship_date, @i_sch_ship_date, @i_date_shipped,
@i_date_entered, @i_req_no, @i_who_entered, @i_status, @i_attention, @i_phone, @i_routing,
@i_special_instr, @i_fob, @i_freight, @i_printed, @i_label_no, @i_no_cartons, @i_who_shipped,
@i_date_printed, @i_who_picked, @i_to_loc_name, @i_to_loc_addr1, @i_to_loc_addr2,
@i_to_loc_addr3, @i_to_loc_addr4, @i_to_loc_addr5, @i_no_pallets, @i_shipper_no,
@i_shipper_name, @i_shipper_addr1, @i_shipper_addr2, @i_shipper_city, @i_shipper_state,
@i_shipper_zip, @i_cust_code, @i_freight_type, @i_note, @i_rec_no, @i_who_recvd, @i_date_recvd,
@i_pick_ctrl_num, @i_from_organization_id, @i_to_organization_id

While @@FETCH_STATUS = 0
begin

  if @i_to_organization_id = ''											-- I/O start
  begin
    select @i_to_organization_id = dbo.adm_get_locations_org_fn(@i_to_loc)
    update xfers_all
    set to_organization_id = @i_to_organization_id 
    where xfer_no = @i_xfer_no
  end
  else
  begin
    if @i_to_organization_id != dbo.adm_get_locations_org_fn(@i_to_loc)
    begin
      select @msg = 'Organization ([' + @i_to_organization_id + ']) is not the current organization for Location ([' + @i_to_loc + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
  end

  if @i_from_organization_id = ''											
  begin
    select @i_from_organization_id = dbo.adm_get_locations_org_fn(@i_from_loc)

    if @i_from_loc not in (select location from dbo.adm_get_related_locs_fn('xfr-f',@i_to_organization_id,4))
    begin
      select @msg = 'From Organization ([' + @i_from_organization_id + ']) is not related to the to organization ([' + @i_to_organization_id + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end 

    update xfers_all
    set from_organization_id = @i_from_organization_id 
    where xfer_no = @i_xfer_no
  end
  else
  begin
    if @i_from_organization_id != dbo.adm_get_locations_org_fn(@i_from_loc)
    begin
      select @msg = 'Organization ([' + @i_from_organization_id + ']) is not the current organization for Location ([' + @i_from_loc + ']).'
      rollback tran
      exec adm_raiserror 832115 ,@msg
      RETURN
    end
    if @i_from_loc not in (select location from dbo.adm_get_related_locs_fn('xfr-f',@i_to_organization_id,4))
    begin
      select @msg = 'From Organization ([' + @i_from_organization_id + ']) is not related to the to organization ([' + @i_to_organization_id + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end 
  end														-- I/O end

  
   exec @tdc_rtn = tdc_xfer_hdr_change @i_xfer_no 

   if (@tdc_rtn< 0 )
   begin
      exec adm_raiserror 87900 ,'Invalid Inventory Update From TDC.'
   end
 


FETCH NEXT FROM t700insxfer_cursor into
@i_xfer_no, @i_from_loc, @i_to_loc, @i_req_ship_date, @i_sch_ship_date, @i_date_shipped,
@i_date_entered, @i_req_no, @i_who_entered, @i_status, @i_attention, @i_phone, @i_routing,
@i_special_instr, @i_fob, @i_freight, @i_printed, @i_label_no, @i_no_cartons, @i_who_shipped,
@i_date_printed, @i_who_picked, @i_to_loc_name, @i_to_loc_addr1, @i_to_loc_addr2,
@i_to_loc_addr3, @i_to_loc_addr4, @i_to_loc_addr5, @i_no_pallets, @i_shipper_no,
@i_shipper_name, @i_shipper_addr1, @i_shipper_addr2, @i_shipper_city, @i_shipper_state,
@i_shipper_zip, @i_cust_code, @i_freight_type, @i_note, @i_rec_no, @i_who_recvd, @i_date_recvd,
@i_pick_ctrl_num, @i_from_organization_id, @i_to_organization_id
end -- while

CLOSE t700insxfer_cursor
DEALLOCATE t700insxfer_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600updxfers] ON [dbo].[xfers_all]   FOR UPDATE  AS
BEGIN


declare @reg int, @reg2 int

declare @xlp int, @ol_stat char(1), @dl_stat char(1),					-- mls 12/20/00 SCR 24912 start
 @msg varchar(255), @retval int

DECLARE @i_xfer_no int, @i_from_loc varchar(10), @i_to_loc varchar(10), @i_req_ship_date datetime,
@i_sch_ship_date datetime, @i_date_shipped datetime, @i_date_entered datetime,
@i_req_no varchar(20), @i_who_entered varchar(20), @i_status char(1), @i_attention varchar(15),
@i_phone varchar(20), @i_routing varchar(20), @i_special_instr varchar(255), @i_fob varchar(10),
@i_freight decimal(20,8), @i_printed char(1), @i_label_no int, @i_no_cartons int,
@i_who_shipped varchar(20), @i_date_printed datetime, @i_who_picked varchar(20),
@i_to_loc_name varchar(40), @i_to_loc_addr1 varchar(40), @i_to_loc_addr2 varchar(40),
@i_to_loc_addr3 varchar(40), @i_to_loc_addr4 varchar(40), @i_to_loc_addr5 varchar(40),
@i_no_pallets int, @i_shipper_no varchar(10), @i_shipper_name varchar(40),
@i_shipper_addr1 varchar(40), @i_shipper_addr2 varchar(40), @i_shipper_city varchar(40),
@i_shipper_state varchar(40), @i_shipper_zip varchar(10), @i_cust_code varchar(10),
@i_freight_type varchar(10), @i_note varchar(255), @i_rec_no int, @i_who_recvd varchar(20),
@i_date_recvd datetime, @i_pick_ctrl_num varchar(32),
@i_from_organization_id varchar(30), @i_to_organization_id varchar(30), @i_back_ord_flag int,
@d_xfer_no int, @d_from_loc varchar(10), @d_to_loc varchar(10), @d_req_ship_date datetime,
@d_sch_ship_date datetime, @d_date_shipped datetime, @d_date_entered datetime,
@d_req_no varchar(20), @d_who_entered varchar(20), @d_status char(1), @d_attention varchar(15),
@d_phone varchar(20), @d_routing varchar(20), @d_special_instr varchar(255), @d_fob varchar(10),
@d_freight decimal(20,8), @d_printed char(1), @d_label_no int, @d_no_cartons int,
@d_who_shipped varchar(20), @d_date_printed datetime, @d_who_picked varchar(20),
@d_to_loc_name varchar(40), @d_to_loc_addr1 varchar(40), @d_to_loc_addr2 varchar(40),
@d_to_loc_addr3 varchar(40), @d_to_loc_addr4 varchar(40), @d_to_loc_addr5 varchar(40),
@d_no_pallets int, @d_shipper_no varchar(10), @d_shipper_name varchar(40),
@d_shipper_addr1 varchar(40), @d_shipper_addr2 varchar(40), @d_shipper_city varchar(40),
@d_shipper_state varchar(40), @d_shipper_zip varchar(10), @d_cust_code varchar(10),
@d_freight_type varchar(10), @d_note varchar(255), @d_rec_no int, @d_who_recvd varchar(20),
@d_date_recvd datetime, @d_pick_ctrl_num varchar(32),
@d_from_organization_id varchar(30), @d_to_organization_id varchar(30)

DECLARE t700updxfer_cursor CURSOR LOCAL STATIC FOR
SELECT i.xfer_no, i.from_loc, i.to_loc, i.req_ship_date, i.sch_ship_date, i.date_shipped,
i.date_entered, i.req_no, i.who_entered, i.status, i.attention, i.phone, i.routing,
i.special_instr, i.fob, i.freight, i.printed, i.label_no, i.no_cartons, i.who_shipped,
i.date_printed, i.who_picked, i.to_loc_name, i.to_loc_addr1, i.to_loc_addr2, i.to_loc_addr3,
i.to_loc_addr4, i.to_loc_addr5, i.no_pallets, i.shipper_no, i.shipper_name, i.shipper_addr1,
i.shipper_addr2, i.shipper_city, i.shipper_state, i.shipper_zip, i.cust_code, i.freight_type,
i.note, i.rec_no, i.who_recvd, i.date_recvd, i.pick_ctrl_num, 
isnull(i.from_organization_id,''), isnull(i.to_organization_id,''), isnull(i.back_ord_flag,0),
d.xfer_no, d.from_loc, d.to_loc, d.req_ship_date, d.sch_ship_date, d.date_shipped,
d.date_entered, d.req_no, d.who_entered, d.status, d.attention, d.phone, d.routing,
d.special_instr, d.fob, d.freight, d.printed, d.label_no, d.no_cartons, d.who_shipped,
d.date_printed, d.who_picked, d.to_loc_name, d.to_loc_addr1, d.to_loc_addr2, d.to_loc_addr3,
d.to_loc_addr4, d.to_loc_addr5, d.no_pallets, d.shipper_no, d.shipper_name, d.shipper_addr1,
d.shipper_addr2, d.shipper_city, d.shipper_state, d.shipper_zip, d.cust_code, d.freight_type,
d.note, d.rec_no, d.who_recvd, d.date_recvd, d.pick_ctrl_num,
isnull(d.from_organization_id,''), isnull(d.to_organization_id,'')
from inserted i, deleted d
where i.xfer_no = d.xfer_no

OPEN t700updxfer_cursor

if @@cursor_rows = 0
begin
CLOSE t700updxfer_cursor
DEALLOCATE t700updxfer_cursor
return
end

FETCH NEXT FROM t700updxfer_cursor into
@i_xfer_no, @i_from_loc, @i_to_loc, @i_req_ship_date, @i_sch_ship_date, @i_date_shipped,
@i_date_entered, @i_req_no, @i_who_entered, @i_status, @i_attention, @i_phone, @i_routing,
@i_special_instr, @i_fob, @i_freight, @i_printed, @i_label_no, @i_no_cartons, @i_who_shipped,
@i_date_printed, @i_who_picked, @i_to_loc_name, @i_to_loc_addr1, @i_to_loc_addr2,
@i_to_loc_addr3, @i_to_loc_addr4, @i_to_loc_addr5, @i_no_pallets, @i_shipper_no,
@i_shipper_name, @i_shipper_addr1, @i_shipper_addr2, @i_shipper_city, @i_shipper_state,
@i_shipper_zip, @i_cust_code, @i_freight_type, @i_note, @i_rec_no, @i_who_recvd, @i_date_recvd,
@i_pick_ctrl_num, @i_from_organization_id, @i_to_organization_id, @i_back_ord_flag,
@d_xfer_no, @d_from_loc, @d_to_loc, @d_req_ship_date, @d_sch_ship_date, @d_date_shipped,
@d_date_entered, @d_req_no, @d_who_entered, @d_status, @d_attention, @d_phone, @d_routing,
@d_special_instr, @d_fob, @d_freight, @d_printed, @d_label_no, @d_no_cartons, @d_who_shipped,
@d_date_printed, @d_who_picked, @d_to_loc_name, @d_to_loc_addr1, @d_to_loc_addr2,
@d_to_loc_addr3, @d_to_loc_addr4, @d_to_loc_addr5, @d_no_pallets, @d_shipper_no,
@d_shipper_name, @d_shipper_addr1, @d_shipper_addr2, @d_shipper_city, @d_shipper_state,
@d_shipper_zip, @d_cust_code, @d_freight_type, @d_note, @d_rec_no, @d_who_recvd, @d_date_recvd,
@d_pick_ctrl_num, @d_from_organization_id, @d_to_organization_id

While @@FETCH_STATUS = 0
begin
  if @i_to_organization_id = ''											-- I/O start
  begin
    select @i_to_organization_id = dbo.adm_get_locations_org_fn(@i_to_loc)
    if @i_to_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_to_loc + ']).'
      rollback tran
      exec adm_raiserror 832115 ,@msg
      RETURN
    end
    else
      update xfers_all
      set to_organization_id = @i_to_organization_id 
      where xfer_no = @i_xfer_no and isnull(to_organization_id,'') != @i_to_organization_id
  end
  else
  begin
    if @i_to_organization_id != dbo.adm_get_locations_org_fn(@i_to_loc) 
    begin
      if @d_status >= 'R'
      begin
        select @msg = 'Organization ([' + @i_to_organization_id + ']) is not the current organization for Location ([' + @i_to_loc + ']).'
        rollback tran
        exec adm_raiserror 832115 ,@msg
        RETURN
      end
      else
      begin
        select @i_to_organization_id = dbo.adm_get_locations_org_fn(@i_to_loc)
        update xfers_all
        set to_organization_id = @i_to_organization_id 
        where xfer_no = @i_xfer_no and isnull(to_organization_id,'') != @i_to_organization_id
      end
    end
  end

  if @i_from_organization_id = ''											
  begin
    select @i_from_organization_id = dbo.adm_get_locations_org_fn(@i_from_loc)

    if @i_from_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_from_loc + ']).'
      rollback tran
      exec adm_raiserror 832115 ,@msg
      RETURN
    end
    else
      update xfers_all
      set from_organization_id = @i_from_organization_id 
      where xfer_no = @i_xfer_no and isnull(from_organization_id,'') != @i_from_organization_id
  end
  else
  begin
    if @i_from_organization_id != dbo.adm_get_locations_org_fn(@i_from_loc)
    begin
      if @d_status >= 'R'
      begin
        select @msg = 'Organization ([' + @i_from_organization_id + ']) is not the current organization for Location ([' + @i_from_loc + ']).'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end
      else
      begin
        select @i_from_organization_id = dbo.adm_get_locations_org_fn(@i_from_loc)
        update xfers_all
        set from_organization_id = @i_from_organization_id 
        where xfer_no = @i_xfer_no and isnull(from_organization_id,'') != @i_from_organization_id
      end
    end
    if @d_status < 'R'
    begin
      if @i_from_loc not in (select location from dbo.adm_get_related_locs_fn('xfr-f',@i_to_organization_id,99))
      begin
        select @msg = 'From Organization ([' + @i_from_organization_id + ']) is not related to the to organization ([' + @i_to_organization_id + ']).  Change the transfer''s from location'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end 
    end 
  end														-- I/O end

  if @i_status = 'S'
  begin
    if exists (select 1 from lot_bin_xfer s where tran_no = @i_xfer_no
      and not exists (select 1 from xfer_list l where l.xfer_no = @i_xfer_no 
      and l.line_no = s.line_no))
    begin
      select @msg = 'Lot bin records on lot_bin_xfer do not relate to a line on the transfer.'
      rollback tran
      exec adm_raiserror 832114, @msg
      RETURN
    end
  end

  if @d_status = 'R' and @i_status < @d_status
  begin
      select @msg = 'Transfer already shipped.  Cannot unship it.'
      rollback tran
      exec adm_raiserror 832114, @msg
      RETURN
  end
  if @i_status != @d_status and @i_status = 'R'
  begin
	if @i_back_ord_flag = 1 -- ship complete
    begin
      if exists (select 1 from xfer_list where xfer_no = @i_xfer_no and ordered > shipped)
      begin
   	    rollback tran
	    exec adm_raiserror 832114, 'Transfer must be shipped complete.'
  	    return
      end
    end

    exec @retval = fs_create_backorder_xfer @i_xfer_no
    if @retval != 1 
    begin
 	  rollback tran
	  exec adm_raiserror 832114 ,'Error Creating Backorder.'
  	  return
    end
  end						

  if @d_status = 'S' and @i_status < @d_status
  begin
      select @msg = 'Transfer already received.  Cannot unreceive it.'
      rollback tran
      exec adm_raiserror 832114, @msg
      RETURN
  end

if @i_status != @d_status and @i_status = 'S'
begin
  update xfer_list
  set status= @i_status
  where xfer_no = @i_xfer_no and status != @i_status
end											-- mls 12/20/00 SCR 24912 end




  declare @tdc_rtn int

  exec @tdc_rtn = tdc_xfer_hdr_change @i_xfer_no

  if (@tdc_rtn< 0 )
  begin
    exec adm_raiserror 97900, 'Invalid Inventory Update From TDC.'
  end



FETCH NEXT FROM t700updxfer_cursor into
@i_xfer_no, @i_from_loc, @i_to_loc, @i_req_ship_date, @i_sch_ship_date, @i_date_shipped,
@i_date_entered, @i_req_no, @i_who_entered, @i_status, @i_attention, @i_phone, @i_routing,
@i_special_instr, @i_fob, @i_freight, @i_printed, @i_label_no, @i_no_cartons, @i_who_shipped,
@i_date_printed, @i_who_picked, @i_to_loc_name, @i_to_loc_addr1, @i_to_loc_addr2,
@i_to_loc_addr3, @i_to_loc_addr4, @i_to_loc_addr5, @i_no_pallets, @i_shipper_no,
@i_shipper_name, @i_shipper_addr1, @i_shipper_addr2, @i_shipper_city, @i_shipper_state,
@i_shipper_zip, @i_cust_code, @i_freight_type, @i_note, @i_rec_no, @i_who_recvd, @i_date_recvd,
@i_pick_ctrl_num, @i_from_organization_id, @i_to_organization_id, @i_back_ord_flag,
@d_xfer_no, @d_from_loc, @d_to_loc, @d_req_ship_date, @d_sch_ship_date, @d_date_shipped,
@d_date_entered, @d_req_no, @d_who_entered, @d_status, @d_attention, @d_phone, @d_routing,
@d_special_instr, @d_fob, @d_freight, @d_printed, @d_label_no, @d_no_cartons, @d_who_shipped,
@d_date_printed, @d_who_picked, @d_to_loc_name, @d_to_loc_addr1, @d_to_loc_addr2,
@d_to_loc_addr3, @d_to_loc_addr4, @d_to_loc_addr5, @d_no_pallets, @d_shipper_no,
@d_shipper_name, @d_shipper_addr1, @d_shipper_addr2, @d_shipper_city, @d_shipper_state,
@d_shipper_zip, @d_cust_code, @d_freight_type, @d_note, @d_rec_no, @d_who_recvd, @d_date_recvd,
@d_pick_ctrl_num, @d_from_organization_id, @d_to_organization_id
end -- while

CLOSE t700updxfer_cursor
DEALLOCATE t700updxfer_cursor

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			xfers_all_ins_trg		
Type:			Trigger
Description:	If transfer is saved with autoship enabled, update processing table
Version:		1.0
Developer:		Chris Tyler

History
-------
v1.0	CT	09/11/2012	Original Version
*/



CREATE TRIGGER [dbo].[xfers_all_ins_trg] ON [dbo].[xfers_all]
FOR INSERT
AS
BEGIN
	DECLARE	@xfer_no		INT,
			@user_id		VARCHAR(50),
			@autoship		INT	-- v1.1


	-- Gte the user name from the current PC client session
	IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL   
	BEGIN  
		SELECT @user_id = who FROM #temp_who
	END
	ELSE
	BEGIN
		SELECT @user_id = suser_sname()
	END

	SET @xfer_no = 0
		
	-- Get the transfer to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@xfer_no = xfer_no
		FROM 
			inserted 
		WHERE
			xfer_no > @xfer_no
			AND ISNULL(autoship,0) = 1
		ORDER BY 
			xfer_no

		IF @@RowCount = 0
			Break

		IF NOT EXISTS (SELECT 1 FROM cvo_autoship_transfer WHERE xfer_no = @xfer_no)
		BEGIN
			INSERT cvo_autoship_transfer(
				xfer_no,
				proc_user_id,
				processed,
				proc_step,
				error_no)
			SELECT
				@xfer_no, 
				@user_id,
				0,
				0,
				0
		END
	END	
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			xfers_all_upd_trg		
Type:			Trigger
Description:	When an autopack transfer's pick ticket is printed (status = Q), call autopack functionality
Version:		1.0
Developer:		Chris Tyler

History
-------
v1.0	CT	09/11/2012	Original Version
v1.1	CT	09/11/2012	Check for checking/unchecking of autoship
v1.2	CT	20/11/2012	If voiding a transfer remove autopack/autoship record
v1.3	CT	29/11/2012	Autopacking of transfer now takes place after allocation instead of pick ticket print, remove code for pick ticket print
*/



CREATE TRIGGER [dbo].[xfers_all_upd_trg] ON [dbo].[xfers_all]
FOR UPDATE
AS
BEGIN
	DECLARE	@xfer_no		INT,
			@user_id		VARCHAR(50),
			@autoship		INT	-- v1.1


	-- Get the user name from the current PC client session
	IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL   
	BEGIN  
		SELECT @user_id = who FROM #temp_who
	END
	ELSE
	BEGIN
		SELECT @user_id = suser_sname()
	END

	-- START v1.3 - remove this code
	/*
	SET @xfer_no = 0
		
	-- Get the transfer to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@xfer_no = i.xfer_no
		FROM 
			inserted i
		INNER JOIN
			deleted d
		ON
			i.xfer_no = d.xfer_no
		WHERE
			i.xfer_no > @xfer_no
			AND ISNULL(i.autopack,0) = 1
			AND i.status = 'Q'
			AND d.status <> 'Q'
		ORDER BY 
			i.xfer_no

		IF @@RowCount = 0
			Break

		INSERT cvo_autopack_transfer(
			xfer_no,
			proc_user_id,
			processed)
		SELECT
			@xfer_no, 
			@user_id,
			0

	END	
	*/
	-- END v1.3

	-- START v1.1
	SET @xfer_no = 0
		
	-- Get the transfer to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@xfer_no = i.xfer_no,
			@autoship = ISNULL(i.autoship,0)
		FROM 
			inserted i
		INNER JOIN
			deleted d
		ON
			i.xfer_no = d.xfer_no
		WHERE
			i.xfer_no > @xfer_no
			AND ISNULL(i.autoship,0) <> ISNULL(d.autoship,0)
		ORDER BY 
			i.xfer_no

		IF @@RowCount = 0
			Break

		IF @autoship = 1
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM cvo_autoship_transfer WHERE xfer_no = @xfer_no)
			BEGIN
				INSERT cvo_autoship_transfer(
					xfer_no,
					proc_user_id,
					processed,
					proc_step,
					error_no)
				SELECT
					@xfer_no, 
					@user_id,
					0,
					0,
					0
			END
		END

		IF @autoship = 0
		BEGIN
			DELETE FROM cvo_autoship_transfer WHERE xfer_no = @xfer_no

		END
	END	
	-- END v1.1

	-- START v1.2
	SET @xfer_no = 0
		
	-- Get the transfer to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@xfer_no = i.xfer_no
		FROM 
			inserted i
		INNER JOIN
			deleted d
		ON
			i.xfer_no = d.xfer_no
		WHERE
			i.xfer_no > @xfer_no
			AND i.status = 'V'
			AND i.status <> d.status
		ORDER BY 
			i.xfer_no

		IF @@RowCount = 0
			Break

		DELETE FROM cvo_autoship_transfer WHERE xfer_no = @xfer_no
		DELETE FROM cvo_autopack_transfer WHERE xfer_no = @xfer_no

	END	
	-- END v1.2
END
GO
CREATE NONCLUSTERED INDEX [xfer2] ON [dbo].[xfers_all] ([date_shipped]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [xfer3] ON [dbo].[xfers_all] ([proc_po_no], [xfer_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [xfer4] ON [dbo].[xfers_all] ([status], [proc_po_no], [xfer_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [xfer1] ON [dbo].[xfers_all] ([xfer_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[xfers_all] TO [public]
GO
GRANT SELECT ON  [dbo].[xfers_all] TO [public]
GO
GRANT INSERT ON  [dbo].[xfers_all] TO [public]
GO
GRANT DELETE ON  [dbo].[xfers_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[xfers_all] TO [public]
GO
