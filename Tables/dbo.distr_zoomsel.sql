CREATE TABLE [dbo].[distr_zoomsel]
(
[timestamp] [timestamp] NOT NULL,
[app_zoom_id] [smallint] NOT NULL,
[zoom_id] [int] NOT NULL,
[zoom_title] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[zoom_desc] [char] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[restrict_hdlr] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[statement] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[size_width] [smallint] NOT NULL,
[size_height] [smallint] NOT NULL,
[page_size] [smallint] NOT NULL,
[literal] [smallint] NOT NULL,
[show_voids] [smallint] NOT NULL,
[void_col] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Tmp_distr__void___6DA32CF2] DEFAULT (''),
[rtrn_row_cnt] [int] NOT NULL,
[filter_col] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Tmp_distr__filte__6E97512B] DEFAULT (''),
[status_col] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Tmp_distr__statu__6F8B7564] DEFAULT ('')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[t735deldistrzsel] ON [dbo].[distr_zoomsel] FOR DELETE AS 
begin
declare @d_app_zoom_id int, @d_zoom_id int,
@win varchar(255), @dw varchar(255), @col varchar(255),
@msg varchar(1000)

DECLARE t735del_distrzsel CURSOR LOCAL STATIC FOR
SELECT d.app_zoom_id, d.zoom_id
from deleted d

OPEN t735del_distrzsel

if @@cursor_rows = 0
begin
  CLOSE t735del_distrzsel
  DEALLOCATE t735del_distrzsel
  return
end

FETCH NEXT FROM t735del_distrzsel into @d_app_zoom_id, @d_zoom_id

While @@FETCH_STATUS = 0
begin
select @win = NULL
set rowcount 1
select @win = window_nm, @dw = datawin_nm, @col = col_nm
from distr_zoomind
where app_zoom_id = @d_app_zoom_id and zoom_id = @d_zoom_id
set rowcount 0

if @win is not NULL
begin
select @msg = 'Zoom Select linked to [' + rtrim(@win) + '.' + rtrim(@dw) + '.' + rtrim(@col) + '] so it cannot be deleted.'
rollback tran
exec adm_raiserror 51000 ,@msg
end

delete distr_zoomfld
where app_zoom_id = @d_app_zoom_id and zoom_id = @d_zoom_id

FETCH NEXT FROM t735del_distrzsel into @d_app_zoom_id, @d_zoom_id
end -- while

CLOSE t735del_distrzsel
DEALLOCATE t735del_distrzsel

END
GO
CREATE UNIQUE CLUSTERED INDEX [zoomsel_0] ON [dbo].[distr_zoomsel] ([app_zoom_id], [zoom_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [zoomsel_1] ON [dbo].[distr_zoomsel] ([zoom_title]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[distr_zoomsel] TO [public]
GO
GRANT INSERT ON  [dbo].[distr_zoomsel] TO [public]
GO
GRANT DELETE ON  [dbo].[distr_zoomsel] TO [public]
GO
GRANT UPDATE ON  [dbo].[distr_zoomsel] TO [public]
GO
