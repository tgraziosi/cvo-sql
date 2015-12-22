CREATE TABLE [dbo].[load_master_all]
(
[timestamp] [timestamp] NOT NULL,
[load_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[truck_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trailer_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[driver_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[driver_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pro_number] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routing] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stop_count] [int] NOT NULL,
[total_miles] [int] NOT NULL,
[sch_ship_date] [datetime] NULL,
[date_shipped] [datetime] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__orig___0080F73C] DEFAULT (''),
[hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__hold___01751B75] DEFAULT (''),
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__conta__02693FAE] DEFAULT (''),
[contact_phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__conta__035D63E7] DEFAULT (''),
[invoice_type] [int] NOT NULL CONSTRAINT [DF__load_mast__invoi__04518820] DEFAULT ((0)),
[create_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__creat__0545AC59] DEFAULT (''),
[user_hold_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__user___0639D092] DEFAULT (''),
[credit_hold_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__credi__072DF4CB] DEFAULT (''),
[picked_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__picke__08221904] DEFAULT (''),
[shipped_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__shipp__09163D3D] DEFAULT (''),
[posted_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__poste__0A0A6176] DEFAULT (''),
[create_dt] [datetime] NOT NULL CONSTRAINT [DF__load_mast__creat__0AFE85AF] DEFAULT (getdate()),
[process_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__load_mast__proce__0BF2A9E8] DEFAULT (''),
[user_hold_dt] [datetime] NULL,
[credit_hold_dt] [datetime] NULL,
[picked_dt] [datetime] NULL,
[posted_dt] [datetime] NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t730delloadm] ON [dbo].[load_master_all] FOR DELETE AS 
BEGIN
DECLARE @d_load_no int,
@d_location varchar(10),@d_truck_no varchar(10), @d_trailer_no varchar(10), @d_driver_key varchar(10),
@d_driver_name varchar(50), @d_pro_number varchar(15), @d_routing varchar(10), @d_stop_count int,
@d_total_miles int, @d_sch_ship_date datetime, @d_date_shipped datetime, @d_status char(1),
@d_hold_reason varchar(10), @d_contact_name varchar(40), @d_contact_phone varchar(20), @d_invoice_type int,
@d_create_who_nm varchar(20), @d_user_hold_who_nm varchar(20), @d_credit_hold_who_nm varchar(20),
@d_picked_who_nm varchar(20),@d_shipped_who_nm varchar(20), @d_posted_who_nm varchar(20), @d_create_dt datetime,
@d_user_hold_dt datetime, @d_credit_hold_dt datetime, @d_picked_dt datetime, @d_posted_dt datetime

DECLARE loadmdel CURSOR LOCAL FOR
SELECT 
load_no,location,truck_no,trailer_no,driver_key,driver_name,pro_number,routing,stop_count,total_miles,
sch_ship_date,date_shipped,status,hold_reason,contact_name,contact_phone,invoice_type,create_who_nm,
user_hold_who_nm,credit_hold_who_nm,picked_who_nm,shipped_who_nm,posted_who_nm,create_dt,user_hold_dt,
credit_hold_dt,picked_dt,posted_dt
from deleted
order by load_no

OPEN loadmdel
FETCH NEXT FROM loadmdel INTO
@d_load_no, @d_location, @d_truck_no, @d_trailer_no, @d_driver_key, @d_driver_name, @d_pro_number, @d_routing, 
@d_stop_count, @d_total_miles, @d_sch_ship_date, @d_date_shipped, @d_status, @d_hold_reason, @d_contact_name, 
@d_contact_phone, @d_invoice_type, @d_create_who_nm, @d_user_hold_who_nm, @d_credit_hold_who_nm, @d_picked_who_nm, 
@d_shipped_who_nm, @d_posted_who_nm, @d_create_dt, @d_user_hold_dt, @d_credit_hold_dt, @d_picked_dt, @d_posted_dt


While @@FETCH_STATUS = 0
begin

  FETCH NEXT FROM loadmdel INTO
  @d_load_no, @d_location, @d_truck_no, @d_trailer_no, @d_driver_key, @d_driver_name, @d_pro_number, @d_routing, 
  @d_stop_count, @d_total_miles, @d_sch_ship_date, @d_date_shipped, @d_status, @d_hold_reason, @d_contact_name, 
  @d_contact_phone, @d_invoice_type, @d_create_who_nm, @d_user_hold_who_nm, @d_credit_hold_who_nm, @d_picked_who_nm, 
  @d_shipped_who_nm, @d_posted_who_nm, @d_create_dt, @d_user_hold_dt, @d_credit_hold_dt, @d_picked_dt, @d_posted_dt
end -- while

close loadmdel
deallocate loadmdel
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t730insloadm] ON [dbo].[load_master_all] FOR INSERT AS 
BEGIN
DECLARE @i_load_no int,
@i_location varchar(10),@i_truck_no varchar(10), @i_trailer_no varchar(10), @i_driver_key varchar(10),
@i_driver_name varchar(50), @i_pro_number varchar(15), @i_routing varchar(10), @i_stop_count int,
@i_total_miles int, @i_sch_ship_date datetime, @i_date_shipped datetime, @i_status char(1),
@i_hold_reason varchar(10), @i_contact_name varchar(40), @i_contact_phone varchar(20), @i_invoice_type int,
@i_create_who_nm varchar(20), @i_user_hold_who_nm varchar(20), @i_credit_hold_who_nm varchar(20),
@i_picked_who_nm varchar(20),@i_shipped_who_nm varchar(20), @i_posted_who_nm varchar(20), @i_create_dt datetime,
@i_user_hold_dt datetime, @i_credit_hold_dt datetime, @i_picked_dt datetime, @i_posted_dt datetime,
@i_organization_id varchar(30)

declare @msg varchar(255), @org_id varchar(30)

DECLARE loadmins CURSOR LOCAL FOR
SELECT 
load_no,location,truck_no,trailer_no,driver_key,driver_name,pro_number,routing,stop_count,total_miles,
sch_ship_date,date_shipped,status,hold_reason,contact_name,contact_phone,invoice_type,create_who_nm,
user_hold_who_nm,credit_hold_who_nm,picked_who_nm,shipped_who_nm,posted_who_nm,create_dt,user_hold_dt,
credit_hold_dt,picked_dt,posted_dt, isnull(organization_id,'')
from inserted
order by load_no

OPEN loadmins
FETCH NEXT FROM loadmins INTO
@i_load_no, @i_location, @i_truck_no, @i_trailer_no, @i_driver_key, @i_driver_name, @i_pro_number, @i_routing, 
@i_stop_count, @i_total_miles, @i_sch_ship_date, @i_date_shipped, @i_status, @i_hold_reason, @i_contact_name, 
@i_contact_phone, @i_invoice_type, @i_create_who_nm, @i_user_hold_who_nm, @i_credit_hold_who_nm, @i_picked_who_nm, 
@i_shipped_who_nm, @i_posted_who_nm, @i_create_dt, @i_user_hold_dt, @i_credit_hold_dt, @i_picked_dt, @i_posted_dt,
@i_organization_id

While @@FETCH_STATUS = 0
begin
  if @i_load_no = 0
  begin
    rollback tran
    exec adm_raiserror 2001001, 'A shipment number must be assigned!'
    return
  end

  if @i_location != ''
  begin
    if not exists (select 1 from locations where location = @i_location and void = 'N')
    begin
      rollback tran
      exec adm_raiserror 2001002, 'The shipment must be assigned to a valid location!'
      return
    end
  end

  if @i_organization_id = ''											-- I/O start
  begin
    select @i_organization_id = dbo.adm_get_locations_org_fn(@i_location)
    if @i_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_location + ']).'
      rollback tran
      exec adm_raiserror 832115 ,@msg
      RETURN
    end
    else
      update load_master_all
      set organization_id = @i_organization_id 
      where load_no = @i_load_no and isnull(organization_id,'') != @i_organization_id
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_location) 
    if @i_organization_id != @org_id 
    begin
      select @i_organization_id = @org_id
      update load_master_all
      set organization_id = @i_organization_id 
      where load_no = @i_load_no and isnull(organization_id,'') != @i_organization_id
    end
  end														-- I/O end

  if @i_status in ('C','R','S','T') 
  begin
    rollback tran
    exec adm_raiserror 2001003, 'Shipment cannot be created in a shipped status!'
    return
  end

  FETCH NEXT FROM loadmins INTO
  @i_load_no, @i_location, @i_truck_no, @i_trailer_no, @i_driver_key, @i_driver_name, @i_pro_number, @i_routing, 
  @i_stop_count, @i_total_miles, @i_sch_ship_date, @i_date_shipped, @i_status, @i_hold_reason, @i_contact_name, 
  @i_contact_phone, @i_invoice_type, @i_create_who_nm, @i_user_hold_who_nm, @i_credit_hold_who_nm, @i_picked_who_nm, 
  @i_shipped_who_nm, @i_posted_who_nm, @i_create_dt, @i_user_hold_dt, @i_credit_hold_dt, @i_picked_dt, @i_posted_dt,
  @i_organization_id
end -- while

close loadmins
deallocate loadmins
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t730updloadm] ON [dbo].[load_master_all] FOR UPDATE AS 
BEGIN
DECLARE @i_load_no int,
@i_location varchar(10),@i_truck_no varchar(10), @i_trailer_no varchar(10), @i_driver_key varchar(10),
@i_driver_name varchar(50), @i_pro_number varchar(15), @i_routing varchar(10), @i_stop_count int,
@i_total_miles int, @i_sch_ship_date datetime, @i_date_shipped datetime, @i_status char(1),
@i_hold_reason varchar(10), @i_contact_name varchar(40), @i_contact_phone varchar(20), @i_invoice_type int,
@i_create_who_nm varchar(20), @i_user_hold_who_nm varchar(20), @i_credit_hold_who_nm varchar(20),
@i_picked_who_nm varchar(20),@i_shipped_who_nm varchar(20), @i_posted_who_nm varchar(20), @i_create_dt datetime,
@i_user_hold_dt datetime, @i_credit_hold_dt datetime, @i_picked_dt datetime, @i_posted_dt datetime,
@i_process_ctrl_num varchar(32)
DECLARE @d_load_no int,
@d_location varchar(10),@d_truck_no varchar(10), @d_trailer_no varchar(10), @d_driver_key varchar(10),
@d_driver_name varchar(50), @d_pro_number varchar(15), @d_routing varchar(10), @d_stop_count int,
@d_total_miles int, @d_sch_ship_date datetime, @d_date_shipped datetime, @d_status char(1),
@d_hold_reason varchar(10), @d_contact_name varchar(40), @d_contact_phone varchar(20), @d_invoice_type int,
@d_create_who_nm varchar(20), @d_user_hold_who_nm varchar(20), @d_credit_hold_who_nm varchar(20),
@d_picked_who_nm varchar(20),@d_shipped_who_nm varchar(20), @d_posted_who_nm varchar(20), @d_create_dt datetime,
@d_user_hold_dt datetime, @d_credit_hold_dt datetime, @d_picked_dt datetime, @d_posted_dt datetime,
@d_process_ctrl_num varchar(32), @i_organization_id varchar(30)

declare @msg varchar(255), @org_id varchar(30)

DECLARE loadmupd CURSOR LOCAL FOR
SELECT 
i.load_no,i.location,i.truck_no,i.trailer_no,i.driver_key,i.driver_name,i.pro_number,i.routing,i.stop_count,i.total_miles,
i.sch_ship_date,i.date_shipped,i.status,i.hold_reason,i.contact_name,i.contact_phone,i.invoice_type,i.create_who_nm,
i.user_hold_who_nm,i.credit_hold_who_nm,i.picked_who_nm,i.shipped_who_nm,i.posted_who_nm,i.create_dt,i.user_hold_dt,
i.credit_hold_dt,i.picked_dt,i.posted_dt,i.process_ctrl_num, isnull(i.organization_id,''),
d.load_no,d.location,d.truck_no,d.trailer_no,d.driver_key,d.driver_name,d.pro_number,d.routing,d.stop_count,d.total_miles,
d.sch_ship_date,d.date_shipped,d.status,d.hold_reason,d.contact_name,d.contact_phone,d.invoice_type,d.create_who_nm,
d.user_hold_who_nm,d.credit_hold_who_nm,d.picked_who_nm,d.shipped_who_nm,d.posted_who_nm,d.create_dt,d.user_hold_dt,
d.credit_hold_dt,d.picked_dt,d.posted_dt,d.process_ctrl_num
from inserted i
left outer join deleted d on i.load_no = d.load_no
order by i.load_no

OPEN loadmupd
FETCH NEXT FROM loadmupd INTO
@i_load_no, @i_location, @i_truck_no, @i_trailer_no, @i_driver_key, @i_driver_name, @i_pro_number, @i_routing, 
@i_stop_count, @i_total_miles, @i_sch_ship_date, @i_date_shipped, @i_status, @i_hold_reason, @i_contact_name, 
@i_contact_phone, @i_invoice_type, @i_create_who_nm, @i_user_hold_who_nm, @i_credit_hold_who_nm, @i_picked_who_nm, 
@i_shipped_who_nm, @i_posted_who_nm, @i_create_dt, @i_user_hold_dt, @i_credit_hold_dt, @i_picked_dt, @i_posted_dt,
@i_process_ctrl_num, @i_organization_id,
@d_load_no, @d_location, @d_truck_no, @d_trailer_no, @d_driver_key, @d_driver_name, @d_pro_number, @d_routing, 
@d_stop_count, @d_total_miles, @d_sch_ship_date, @d_date_shipped, @d_status, @d_hold_reason, @d_contact_name, 
@d_contact_phone, @d_invoice_type, @d_create_who_nm, @d_user_hold_who_nm, @d_credit_hold_who_nm, @d_picked_who_nm, 
@d_shipped_who_nm, @d_posted_who_nm, @d_create_dt, @d_user_hold_dt, @d_credit_hold_dt, @d_picked_dt, @d_posted_dt,
@d_process_ctrl_num


While @@FETCH_STATUS = 0
begin
  if @d_load_no is NULL
  begin
    rollback tran
    exec adm_raiserror 2001101, 'You Can NOT Change The shipment number of a shipment!'
    return
  end

  if @d_status = 'C' and @i_status = 'C'
  begin
    rollback tran
    exec adm_raiserror 2001004 ,'You cannot update a shipment in credit hold status!'
    return
  end

  if @d_status = 'V' and @i_status = 'V'
  begin
    rollback tran
    exec adm_raiserror 2001005 ,'You cannot update a shipment that has been voided!'
    return
  end
    
  if @i_location != @d_location
  begin
    if @i_location != ''
    begin
      if not exists (select 1 from locations (nolock) where location = @i_location and void = 'N')
      begin
        rollback tran
        exec adm_raiserror 2001002, 'The shipment must be assigned to a valid location!'
        return
      end
    end
  end

  if @i_organization_id = ''											-- I/O start
  begin
    select @i_organization_id = dbo.adm_get_locations_org_fn(@i_location)
    if @i_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_location + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
    else
      update load_master_all
      set organization_id = @i_organization_id 
      where load_no = @i_load_no and isnull(organization_id,'') != @i_organization_id
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_location) 
    if @i_organization_id != @org_id 
    begin
      select @i_organization_id = @org_id
      update load_master_all
      set organization_id = @i_organization_id 
      where load_no = @i_load_no and isnull(organization_id,'') != @i_organization_id
    end
  end														-- I/O end

  if @i_status in ('C','R') and @i_date_shipped is NULL
  begin
    rollback tran
    exec adm_raiserror 2001003 ,'A valid date shipped must be assigned!'
    return
  end
  if @i_status in ('C','R') and isnull(@i_shipped_who_nm,'') = ''
  begin
    rollback tran
    exec adm_raiserror 2001006 ,'The shipper''s name needs to be entered!'
    return
  end

  if @i_status in ('R','C')
  begin
    if exists (select 1 from load_list ll (nolock), orders_all o (nolock)	-- mls 12/27/06 SCR 37021
    where o.order_no = ll.order_no and o.ext = ll.order_ext and
      ll.load_no = @i_load_no and o.status < 'N')
    begin
      rollback tran
      exec adm_raiserror 2001007, 'You cannot ship a load that has orders in a hold status'
      return
    end

    update o
    set status = 'R', printed = 'R', date_shipped = @i_date_shipped
    from load_list ll, orders_all o
    where o.order_no = ll.order_no and o.ext = ll.order_ext and
      ll.load_no = @i_load_no and
      not (o.status = 'R' and o.printed = 'R' and o.date_shipped = @i_date_shipped)
  end

  if @i_status = 'V'
  begin
    update o
    set load_no = 0
    from load_list ll, orders_all o
    where o.order_no = ll.order_no and o.ext = ll.order_ext and
      ll.load_no = @i_load_no 

    delete from load_list
    where load_no = @i_load_no
  end

  if @d_status in ('R','C') and @i_status between 'N' and 'Q'
  begin
    update o
    set status = 'Q', printed = 'Q', date_shipped = NULL
    from load_list ll, orders_all o
    where o.order_no = ll.order_no and o.ext = ll.order_ext and
      ll.load_no = @i_load_no and
      not (o.status = 'Q' and o.printed = 'Q' and o.date_shipped is NULL)
  end

  if @i_status = 'S' 
  begin
    if exists (select 1 from load_list ll (nolock), orders_all o (nolock)	-- mls 12/27/06 SCR 37021
    where o.order_no = ll.order_no and o.ext = ll.order_ext and
      ll.load_no = @i_load_no and o.status < 'N')
    begin
      rollback tran
      exec adm_raiserror 2001007 ,'You cannot post a load that has orders in a hold status'
      return
    end

    update o
    set status = 'S', printed = 'S', process_ctrl_num = @i_process_ctrl_num
    from load_list ll, orders_all o
    where o.order_no = ll.order_no and o.ext = ll.order_ext and
      ll.load_no = @i_load_no and
      not (o.status = 'S' and o.printed = 'S' and o.process_ctrl_num = @i_process_ctrl_num)
  end

  if @i_status = 'P' and @d_status > 'P'
  begin
    update o
    set status = 'P', printed = 'P'
    from load_list ll, orders_all o
    where o.order_no = ll.order_no and o.ext = ll.order_ext and
      ll.load_no = @i_load_no and o.status = 'Q'
  end

  if @i_status = 'N' and @d_status > 'N'
  begin
    update o
    set status = 'N', printed = 'N'
    from load_list ll, orders_all o
    where o.order_no = ll.order_no and o.ext = ll.order_ext and
      ll.load_no = @i_load_no and o.status in ('P','Q') 
  end

  FETCH NEXT FROM loadmupd INTO
  @i_load_no, @i_location, @i_truck_no, @i_trailer_no, @i_driver_key, @i_driver_name, @i_pro_number, @i_routing, 
  @i_stop_count, @i_total_miles, @i_sch_ship_date, @i_date_shipped, @i_status, @i_hold_reason, @i_contact_name, 
  @i_contact_phone, @i_invoice_type, @i_create_who_nm, @i_user_hold_who_nm, @i_credit_hold_who_nm, @i_picked_who_nm, 
  @i_shipped_who_nm, @i_posted_who_nm, @i_create_dt, @i_user_hold_dt, @i_credit_hold_dt, @i_picked_dt, @i_posted_dt,
  @i_process_ctrl_num, @i_organization_id,
  @d_load_no, @d_location, @d_truck_no, @d_trailer_no, @d_driver_key, @d_driver_name, @d_pro_number, @d_routing, 
  @d_stop_count, @d_total_miles, @d_sch_ship_date, @d_date_shipped, @d_status, @d_hold_reason, @d_contact_name, 
  @d_contact_phone, @d_invoice_type, @d_create_who_nm, @d_user_hold_who_nm, @d_credit_hold_who_nm, @d_picked_who_nm, 
  @d_shipped_who_nm, @d_posted_who_nm, @d_create_dt, @d_user_hold_dt, @d_credit_hold_dt, @d_picked_dt, @d_posted_dt,
  @d_process_ctrl_num
end -- while

close loadmupd
deallocate loadmupd
END

GO
ALTER TABLE [dbo].[load_master_all] ADD CONSTRAINT [CK_load_master_invoice_type] CHECK (([invoice_type]=(1) OR [invoice_type]=(0)))
GO
ALTER TABLE [dbo].[load_master_all] ADD CONSTRAINT [ck_load_master_status] CHECK (([status]='V' OR [status]='T' OR [status]='S' OR [status]='R' OR [status]='Q' OR [status]='P' OR [status]='N' OR [status]='H' OR [status]='C'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [load_master_ndx] ON [dbo].[load_master_all] ([load_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[load_master_all] TO [public]
GO
GRANT SELECT ON  [dbo].[load_master_all] TO [public]
GO
GRANT INSERT ON  [dbo].[load_master_all] TO [public]
GO
GRANT DELETE ON  [dbo].[load_master_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[load_master_all] TO [public]
GO
