CREATE TABLE [dbo].[prod_list_cost]
(
[timestamp] [timestamp] NOT NULL,
[prod_no] [int] NOT NULL,
[prod_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cost] [decimal] (20, 8) NOT NULL,
[labor] [decimal] (20, 8) NOT NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[tran_date] [datetime] NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[qty] [decimal] (20, 8) NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tot_mtrl_cost] [decimal] (20, 8) NULL,
[tot_dir_cost] [decimal] (20, 8) NULL,
[tot_ovhd_cost] [decimal] (20, 8) NULL,
[tot_util_cost] [decimal] (20, 8) NULL,
[tot_labor_cost] [decimal] (20, 8) NULL,
[tran_id] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[t700delprodcost] ON [dbo].[prod_list_cost] FOR delete AS 
BEGIN

DECLARE @d_prod_no int, @d_prod_ext int, @d_line_no int, @d_part_no varchar(30),
@d_cost decimal(20,8), @d_labor decimal(20,8), @d_direct_dolrs decimal(20,8),
@d_ovhd_dolrs decimal(20,8), @d_util_dolrs decimal(20,8), @d_tran_date datetime, @d_row_id int,
@d_qty decimal(20,8), @d_status char(1), @d_tot_mtrl_cost decimal(20,8),
@d_tot_dir_cost decimal(20,8), @d_tot_ovhd_cost decimal(20,8), @d_tot_util_cost decimal(20,8),
@d_tot_labor_cost decimal(20,8)
declare @direction int

DECLARE t700delprod_cursor CURSOR LOCAL STATIC FOR
SELECT d.prod_no, d.prod_ext, d.line_no, d.part_no, d.cost, d.labor, d.direct_dolrs,
d.ovhd_dolrs, d.util_dolrs, d.tran_date, d.row_id, d.qty, d.status, d.tot_mtrl_cost,
d.tot_dir_cost, d.tot_ovhd_cost, d.tot_util_cost, d.tot_labor_cost
from deleted d

OPEN t700delprod_cursor

if @@cursor_rows = 0
begin
CLOSE t700delprod_cursor
DEALLOCATE t700delprod_cursor
return
end

FETCH NEXT FROM t700delprod_cursor into
@d_prod_no, @d_prod_ext, @d_line_no, @d_part_no, @d_cost, @d_labor, @d_direct_dolrs,
@d_ovhd_dolrs, @d_util_dolrs, @d_tran_date, @d_row_id, @d_qty, @d_status, @d_tot_mtrl_cost,
@d_tot_dir_cost, @d_tot_ovhd_cost, @d_tot_util_cost, @d_tot_labor_cost

While @@FETCH_STATUS = 0
begin
  select @direction = isnull((select direction from prod_list where prod_no = @d_prod_no and prod_ext = @d_prod_ext
    and line_no = @d_line_no),0)

  
  if @direction < 0
  begin
    UPDATE produce_all SET
	tot_avg_cost=tot_avg_cost - isnull(@d_tot_mtrl_cost,(@d_qty * @d_cost)),
	tot_direct_dolrs=tot_direct_dolrs - isnull(@d_tot_dir_cost,(@d_qty * @d_direct_dolrs)),
	tot_ovhd_dolrs=tot_ovhd_dolrs - isnull(@d_tot_ovhd_cost,(@d_qty * @d_ovhd_dolrs)),
	tot_util_dolrs=tot_util_dolrs - isnull(@d_tot_util_cost,(@d_qty * @d_util_dolrs)),
	tot_labor=tot_labor - isnull(@d_tot_labor_cost,(@d_qty * @d_labor))
    WHERE prod_no=@d_prod_no and prod_ext=@d_prod_ext
  end

  if @direction > 0
  begin
    UPDATE produce_all SET
	tot_prod_avg_cost=tot_prod_avg_cost + isnull(@d_tot_mtrl_cost,(@d_qty * @d_cost)),
	tot_prod_direct_dolrs=tot_prod_direct_dolrs + isnull(@d_tot_dir_cost,(@d_qty * @d_direct_dolrs)),
	tot_prod_ovhd_dolrs=tot_prod_ovhd_dolrs + isnull(@d_tot_ovhd_cost,(@d_qty * @d_ovhd_dolrs)),
	tot_prod_util_dolrs=tot_prod_util_dolrs + isnull(@d_tot_util_cost,(@d_qty * @d_util_dolrs)),
	tot_prod_labor=tot_prod_labor + isnull(@d_tot_labor_cost,(@d_qty * @d_labor))
    WHERE prod_no=@d_prod_no and prod_ext=@d_prod_ext
  end

FETCH NEXT FROM t700delprod_cursor into
@d_prod_no, @d_prod_ext, @d_line_no, @d_part_no, @d_cost, @d_labor, @d_direct_dolrs,
@d_ovhd_dolrs, @d_util_dolrs, @d_tran_date, @d_row_id, @d_qty, @d_status, @d_tot_mtrl_cost,
@d_tot_dir_cost, @d_tot_ovhd_cost, @d_tot_util_cost, @d_tot_labor_cost
end -- while

CLOSE t700delprod_cursor
DEALLOCATE t700delprod_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insprodcost] ON [dbo].[prod_list_cost] FOR insert AS 
BEGIN

DECLARE @i_prod_no int, @i_prod_ext int, @i_line_no int, @i_part_no varchar(30),
@i_cost decimal(20,8), @i_labor decimal(20,8), @i_direct_dolrs decimal(20,8),
@i_ovhd_dolrs decimal(20,8), @i_util_dolrs decimal(20,8), @i_tran_date datetime, @i_row_id int,
@i_qty decimal(20,8), @i_status char(1), @i_tot_mtrl_cost decimal(20,8),
@i_tot_dir_cost decimal(20,8), @i_tot_ovhd_cost decimal(20,8), @i_tot_util_cost decimal(20,8),
@i_tot_labor_cost decimal(20,8)

declare @msg varchar(40), @direction int
DECLARE @retval int

DECLARE t700insprod_cursor CURSOR LOCAL STATIC FOR
SELECT i.prod_no, i.prod_ext, i.line_no, i.part_no, i.cost, i.labor, i.direct_dolrs,
i.ovhd_dolrs, i.util_dolrs, i.tran_date, i.row_id, i.qty, i.status, i.tot_mtrl_cost,
i.tot_dir_cost, i.tot_ovhd_cost, i.tot_util_cost, i.tot_labor_cost
from inserted i

OPEN t700insprod_cursor

if @@cursor_rows = 0
begin
CLOSE t700insprod_cursor
DEALLOCATE t700insprod_cursor
return
end

FETCH NEXT FROM t700insprod_cursor into
@i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, @i_cost, @i_labor, @i_direct_dolrs,
@i_ovhd_dolrs, @i_util_dolrs, @i_tran_date, @i_row_id, @i_qty, @i_status, @i_tot_mtrl_cost,
@i_tot_dir_cost, @i_tot_ovhd_cost, @i_tot_util_cost, @i_tot_labor_cost

While @@FETCH_STATUS = 0
begin
  select @direction = isnull((select direction from prod_list
    where prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @i_line_no),0)

  
  if @direction < 0
  begin
    update produce_all 
     set tot_avg_cost = tot_avg_cost + isnull(@i_tot_mtrl_cost,(@i_qty * @i_cost)),
	tot_direct_dolrs = tot_direct_dolrs + isnull(@i_tot_dir_cost,(@i_qty * @i_direct_dolrs)),
	tot_ovhd_dolrs = tot_ovhd_dolrs + isnull(@i_tot_ovhd_cost,(@i_qty * @i_ovhd_dolrs)),
	tot_util_dolrs = tot_util_dolrs + isnull(@i_tot_util_cost,(@i_qty * @i_util_dolrs)),
	tot_labor = tot_labor + isnull(@i_tot_labor_cost,(@i_qty * @i_labor))
    WHERE prod_no=@i_prod_no and prod_ext=@i_prod_ext
  end
  if @direction > 0
  begin
    update produce_all 
     set tot_prod_avg_cost = tot_prod_avg_cost - isnull(@i_tot_mtrl_cost,(@i_qty * @i_cost)),
	tot_prod_direct_dolrs = tot_prod_direct_dolrs - isnull(@i_tot_dir_cost,(@i_qty * @i_direct_dolrs)),
	tot_prod_ovhd_dolrs = tot_prod_ovhd_dolrs - isnull(@i_tot_ovhd_cost,(@i_qty * @i_ovhd_dolrs)),
	tot_prod_util_dolrs = tot_prod_util_dolrs - isnull(@i_tot_util_cost,(@i_qty * @i_util_dolrs)),
	tot_prod_labor = tot_prod_labor - isnull(@i_tot_labor_cost,(@i_qty * @i_labor))
    WHERE prod_no=@i_prod_no and prod_ext=@i_prod_ext
  end

  --Accounting Feeds
  exec @retval=fs_prodcost_insert @i_row_id

  IF @retval != 1
  BEGIN
    rollback tran
    select @msg = 'fs_prod_cost_insert error [' + str(@retval) + ']'
    exec adm_raiserror 81330, @msg
    RETURN
  END

FETCH NEXT FROM t700insprod_cursor into
@i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, @i_cost, @i_labor, @i_direct_dolrs,
@i_ovhd_dolrs, @i_util_dolrs, @i_tran_date, @i_row_id, @i_qty, @i_status, @i_tot_mtrl_cost,
@i_tot_dir_cost, @i_tot_ovhd_cost, @i_tot_util_cost, @i_tot_labor_cost
end -- while

CLOSE t700insprod_cursor
DEALLOCATE t700insprod_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE TRIGGER [dbo].[t700updprodcost] ON [dbo].[prod_list_cost] FOR update AS 
BEGIN

DECLARE @i_prod_no int, @i_prod_ext int, @i_line_no int, @i_part_no varchar(30),
@i_cost decimal(20,8), @i_labor decimal(20,8), @i_direct_dolrs decimal(20,8),
@i_ovhd_dolrs decimal(20,8), @i_util_dolrs decimal(20,8), @i_tran_date datetime, @i_row_id int,
@i_qty decimal(20,8), @i_status char(1), @i_tot_mtrl_cost decimal(20,8),
@i_tot_dir_cost decimal(20,8), @i_tot_ovhd_cost decimal(20,8), @i_tot_util_cost decimal(20,8),
@i_tot_labor_cost decimal(20,8),
@d_prod_no int, @d_prod_ext int, @d_line_no int, @d_part_no varchar(30),
@d_cost decimal(20,8), @d_labor decimal(20,8), @d_direct_dolrs decimal(20,8),
@d_ovhd_dolrs decimal(20,8), @d_util_dolrs decimal(20,8), @d_tran_date datetime, @d_row_id int,
@d_qty decimal(20,8), @d_status char(1), @d_tot_mtrl_cost decimal(20,8),
@d_tot_dir_cost decimal(20,8), @d_tot_ovhd_cost decimal(20,8), @d_tot_util_cost decimal(20,8),
@d_tot_labor_cost decimal(20,8)

declare @direction int

DECLARE t700updprod_cursor CURSOR LOCAL STATIC FOR
SELECT i.prod_no, i.prod_ext, i.line_no, i.part_no, i.cost, i.labor, i.direct_dolrs,
i.ovhd_dolrs, i.util_dolrs, i.tran_date, i.row_id, i.qty, i.status, i.tot_mtrl_cost,
i.tot_dir_cost, i.tot_ovhd_cost, i.tot_util_cost, i.tot_labor_cost,
d.prod_no, d.prod_ext, d.line_no, d.part_no, d.cost, d.labor, d.direct_dolrs,
d.ovhd_dolrs, d.util_dolrs, d.tran_date, d.row_id, d.qty, d.status, d.tot_mtrl_cost,
d.tot_dir_cost, d.tot_ovhd_cost, d.tot_util_cost, d.tot_labor_cost
from inserted i, deleted d
where i.row_id=d.row_id

OPEN t700updprod_cursor

if @@cursor_rows = 0
begin
CLOSE t700updprod_cursor
DEALLOCATE t700updprod_cursor
return
end

FETCH NEXT FROM t700updprod_cursor into
@i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, @i_cost, @i_labor, @i_direct_dolrs,
@i_ovhd_dolrs, @i_util_dolrs, @i_tran_date, @i_row_id, @i_qty, @i_status, @i_tot_mtrl_cost,
@i_tot_dir_cost, @i_tot_ovhd_cost, @i_tot_util_cost, @i_tot_labor_cost,
@d_prod_no, @d_prod_ext, @d_line_no, @d_part_no, @d_cost, @d_labor, @d_direct_dolrs,
@d_ovhd_dolrs, @d_util_dolrs, @d_tran_date, @d_row_id, @d_qty, @d_status, @d_tot_mtrl_cost,
@d_tot_dir_cost, @d_tot_ovhd_cost, @d_tot_util_cost, @d_tot_labor_cost

While @@FETCH_STATUS = 0
begin
  select @direction = isnull((select direction from prod_list where prod_no = @i_prod_no and prod_ext = @i_prod_ext
    and line_no = @i_line_no),0)

  if @direction < 0
  begin
    UPDATE produce_all SET
	tot_avg_cost=tot_avg_cost - isnull(@d_tot_mtrl_cost,(@d_qty * @d_cost)),
	tot_direct_dolrs=tot_direct_dolrs - isnull(@d_tot_dir_cost,(@d_qty * @d_direct_dolrs)),
	tot_ovhd_dolrs=tot_ovhd_dolrs - isnull(@d_tot_ovhd_cost,(@d_qty * @d_ovhd_dolrs)),
	tot_util_dolrs=tot_util_dolrs - isnull(@d_tot_util_cost,(@d_qty * @d_util_dolrs)),
	tot_labor=tot_labor - isnull(@d_tot_labor_cost,(@d_qty * @d_labor))
    WHERE prod_no=@d_prod_no and prod_ext=@d_prod_ext

    update produce_all set 
	tot_avg_cost=tot_avg_cost + isnull(@i_tot_mtrl_cost,(@i_qty * @i_cost)),
	tot_direct_dolrs=tot_direct_dolrs + isnull(@i_tot_dir_cost,(@i_qty * @i_direct_dolrs)),
	tot_ovhd_dolrs=tot_ovhd_dolrs + isnull(@i_tot_ovhd_cost,(@i_qty * @i_ovhd_dolrs)),
	tot_util_dolrs=tot_util_dolrs + isnull(@i_tot_util_cost,(@i_qty * @i_util_dolrs)),
	tot_labor=tot_labor + isnull(@i_tot_labor_cost,(@i_qty * @i_labor))
    WHERE prod_no=@i_prod_no and prod_ext=@i_prod_ext
  end

  if @direction > 0
  begin
    UPDATE produce_all SET
	tot_prod_avg_cost=tot_prod_avg_cost + isnull(@d_tot_mtrl_cost,(@d_qty * @d_cost)),
	tot_prod_direct_dolrs=tot_prod_direct_dolrs + isnull(@d_tot_dir_cost,(@d_qty * @d_direct_dolrs)),
	tot_prod_ovhd_dolrs=tot_prod_ovhd_dolrs + isnull(@d_tot_ovhd_cost,(@d_qty * @d_ovhd_dolrs)),
	tot_prod_util_dolrs=tot_prod_util_dolrs + isnull(@d_tot_util_cost,(@d_qty * @d_util_dolrs)),
	tot_prod_labor=tot_prod_labor + isnull(@d_tot_labor_cost,(@d_qty * @d_labor))
    WHERE prod_no=@d_prod_no and prod_ext=@d_prod_ext

    update produce_all set 
	tot_prod_avg_cost=tot_prod_avg_cost - isnull(@i_tot_mtrl_cost,(@i_qty * @i_cost)),
	tot_prod_direct_dolrs=tot_prod_direct_dolrs - isnull(@i_tot_dir_cost,(@i_qty * @i_direct_dolrs)),
	tot_prod_ovhd_dolrs=tot_prod_ovhd_dolrs - isnull(@i_tot_ovhd_cost,(@i_qty * @i_ovhd_dolrs)),
	tot_prod_util_dolrs=tot_prod_util_dolrs - isnull(@i_tot_util_cost,(@i_qty * @i_util_dolrs)),
	tot_prod_labor=tot_prod_labor + isnull(@i_tot_labor_cost,(@i_qty * @i_labor))
    WHERE prod_no=@i_prod_no and prod_ext=@i_prod_ext
  end

FETCH NEXT FROM t700updprod_cursor into
@i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, @i_cost, @i_labor, @i_direct_dolrs,
@i_ovhd_dolrs, @i_util_dolrs, @i_tran_date, @i_row_id, @i_qty, @i_status, @i_tot_mtrl_cost,
@i_tot_dir_cost, @i_tot_ovhd_cost, @i_tot_util_cost, @i_tot_labor_cost,
@d_prod_no, @d_prod_ext, @d_line_no, @d_part_no, @d_cost, @d_labor, @d_direct_dolrs,
@d_ovhd_dolrs, @d_util_dolrs, @d_tran_date, @d_row_id, @d_qty, @d_status, @d_tot_mtrl_cost,
@d_tot_dir_cost, @d_tot_ovhd_cost, @d_tot_util_cost, @d_tot_labor_cost
end -- while

CLOSE t700updprod_cursor
DEALLOCATE t700updprod_cursor

END
GO
CREATE NONCLUSTERED INDEX [prodlcost1] ON [dbo].[prod_list_cost] ([prod_no], [prod_ext], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [prodlcost2] ON [dbo].[prod_list_cost] ([row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prod_list_cost] TO [public]
GO
GRANT SELECT ON  [dbo].[prod_list_cost] TO [public]
GO
GRANT INSERT ON  [dbo].[prod_list_cost] TO [public]
GO
GRANT DELETE ON  [dbo].[prod_list_cost] TO [public]
GO
GRANT UPDATE ON  [dbo].[prod_list_cost] TO [public]
GO
