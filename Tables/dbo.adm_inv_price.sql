CREATE TABLE [dbo].[adm_inv_price]
(
[timestamp] [timestamp] NOT NULL,
[inv_price_id] [int] NOT NULL IDENTITY(1, 1),
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_level] [int] NOT NULL,
[loc_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[catalog_id] [int] NOT NULL,
[promo_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_rate] [decimal] (20, 8) NULL,
[promo_date_expires] [datetime] NULL,
[promo_date_entered] [datetime] NULL,
[promo_start_date] [datetime] NULL,
[active_ind] [int] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700deladm_inv_price] ON [dbo].[adm_inv_price] FOR delete AS 
BEGIN

DECLARE
@d_inv_price_id int, @d_part_no varchar(30), @d_org_level int,
@d_loc_org_id varchar(30), @d_catalog_id int, @d_promo_type char(1), @d_promo_rate decimal(20,8),
@d_promo_date_expires datetime, @d_promo_date_entered datetime, @d_promo_start_date datetime,
@d_active_ind int

declare @curr_key varchar(8)

DECLARE t700deladm_ip_cursor CURSOR LOCAL STATIC FOR
SELECT  
d.inv_price_id, d.part_no, d.org_level, d.loc_org_id, d.catalog_id,
d.promo_type, d.promo_rate, d.promo_date_expires, d.promo_date_entered, d.promo_start_date,
d.active_ind
from deleted d

OPEN t700deladm_ip_cursor

if @@cursor_rows = 0
begin
CLOSE t700deladm_ip_cursor
DEALLOCATE t700deladm_ip_cursor
return
end

FETCH NEXT FROM t700deladm_ip_cursor into
@d_inv_price_id, @d_part_no, @d_org_level, @d_loc_org_id, @d_catalog_id,
@d_promo_type, @d_promo_rate, @d_promo_date_expires, @d_promo_date_entered, @d_promo_start_date,
@d_active_ind

While @@FETCH_STATUS = 0
begin
  if @d_org_level = 0
  begin
    select @curr_key = isnull((select curr_key from adm_price_catalog where catalog_id = @d_catalog_id and type = 0),'')

    if @curr_key != ''
    begin
      if exists (select 1 from part_price (nolock) where part_no = @d_part_no and curr_key = @curr_key)
      begin
      delete part_price
      where part_no = @d_part_no and curr_key = @curr_key
    end

    delete adm_inv_price_det
    where inv_price_id = @d_inv_price_id
  end
end

FETCH NEXT FROM t700deladm_ip_cursor into
@d_inv_price_id, @d_part_no, @d_org_level, @d_loc_org_id, @d_catalog_id,
@d_promo_type, @d_promo_rate, @d_promo_date_expires, @d_promo_date_entered, @d_promo_start_date,
@d_active_ind
end -- while

CLOSE t700deladm_ip_cursor
DEALLOCATE t700deladm_ip_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700iuadm_inv_price] ON [dbo].[adm_inv_price] FOR insert, update AS 
BEGIN

DECLARE @i_inv_price_id int, @i_part_no varchar(30), @i_org_level int,
@i_loc_org_id varchar(30), @i_catalog_id int, @i_promo_type char(1), @i_promo_rate decimal(20,8),
@i_promo_date_expires datetime, @i_promo_date_entered datetime, @i_promo_start_date datetime,
@i_active_ind int

declare @curr_key varchar(8)

DECLARE t700insadm_ip_cursor CURSOR LOCAL STATIC FOR
SELECT  i.inv_price_id, i.part_no, i.org_level, i.loc_org_id, i.catalog_id,
i.promo_type, i.promo_rate, i.promo_date_expires, i.promo_date_entered, i.promo_start_date,
i.active_ind
from inserted i

OPEN t700insadm_ip_cursor

if @@cursor_rows = 0
begin
CLOSE t700insadm_ip_cursor
DEALLOCATE t700insadm_ip_cursor
return
end

FETCH NEXT FROM t700insadm_ip_cursor into
@i_inv_price_id, @i_part_no, @i_org_level, @i_loc_org_id, @i_catalog_id,
@i_promo_type, @i_promo_rate, @i_promo_date_expires, @i_promo_date_entered, @i_promo_start_date,
@i_active_ind

While @@FETCH_STATUS = 0
begin
  if @i_org_level = 0
  begin
    select @curr_key = isnull((select curr_key from adm_price_catalog where catalog_id = @i_catalog_id and type = 0),'')

    if @curr_key != ''
    begin
      if exists (select 1 from part_price (nolock) where part_no = @i_part_no and curr_key = @curr_key)
      begin
      update part_price 
      set promo_type = @i_promo_type,
        promo_rate = @i_promo_rate,
        promo_date_expires = @i_promo_date_expires,
        promo_start_date = @i_promo_start_date,
        promo_date_entered = @i_promo_date_entered,
        last_system_upd_date = getdate()
      where part_no = @i_part_no and curr_key = @curr_key
    end
    else
    begin
      insert part_price (part_no, curr_key, promo_type, promo_rate, promo_date_expires, promo_start_date, promo_date_entered, last_system_upd_date,
        qty_a, qty_b, qty_c, qty_d, qty_e, qty_f, price_a, price_b, price_c, price_d, price_e, price_f)
      select @i_part_no, @curr_key, @i_promo_type, @i_promo_rate, @i_promo_date_expires, @i_promo_start_date, @i_promo_date_entered, getdate(),
         0,0,0,0,0,0, 0,0,0,0,0,0
    end        
  end
end

FETCH NEXT FROM t700insadm_ip_cursor into
@i_inv_price_id, @i_part_no, @i_org_level, @i_loc_org_id, @i_catalog_id,
@i_promo_type, @i_promo_rate, @i_promo_date_expires, @i_promo_date_entered, @i_promo_start_date,
@i_active_ind
end -- while

CLOSE t700insadm_ip_cursor
DEALLOCATE t700insadm_ip_cursor

END
GO
CREATE UNIQUE CLUSTERED INDEX [adm_inv_price_0] ON [dbo].[adm_inv_price] ([inv_price_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_inv_price_1] ON [dbo].[adm_inv_price] ([part_no], [org_level], [loc_org_id], [catalog_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_inv_price] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_inv_price] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_inv_price] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_inv_price] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_inv_price] TO [public]
GO
