CREATE TABLE [dbo].[inv_revisions]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[revision] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NOT NULL,
[note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delinvr] ON [dbo].[inv_revisions] 
FOR DELETE 
AS
begin

if NOT exists (select * from inv_master m, inserted i where i.part_no=m.part_no) return
if exists (select * from config where flag='TRIG_DEL_INVM' and value_str='DISABLE')
	begin
		return
	end
else
	begin
	rollback tran
	exec adm_raiserror 73198, 'You Can Not Delete Inventory Revisions!'
	return
	end 
end

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t601insinvr] ON [dbo].[inv_revisions] 
FOR INSERT 
AS
BEGIN
declare @pn varchar(30), @rev char(10)
if exists (select * from config where flag='TRIG_DEL_INV' and value_str='DISABLE')
begin
   return
end
else
begin
   select @pn=isnull( (select min(part_no) from inserted), '' )

   while @pn > '' begin



      SELECT @rev=isnull((select max( space(10 - len(inv_revisions.revision))  + inv_revisions.revision  ) from inv_revisions, inserted
             where inserted.part_no=inv_revisions.part_no and 
                   inserted.part_no=@pn and 
                   space(10 - len(inv_revisions.revision))  + inv_revisions.revision   < 
                   space(10 - len(inserted.revision))  + inserted.revision  ), ' ' )		-- mls 9/24/03 SCR 31923

select @rev = ltrim(@rev)

      INSERT what_hist (
         asm_no        , revision      , seq_no        , 
         part_no       , qty           , attrib        , 
         uom           , active        , who_entered   , 
         bench_stock   , eff_date      , date_entered  , 
         conv_factor   , constrain     , fixed         , 
         alt_seq_no    , note          , note2         , 
         note3         , note4         , plan_pcs      , 
         lag_qty       , cost_pct      , location      ,
         pool_qty
) 
      SELECT
         asm_no        , @rev          , seq_no        , 
         part_no       , qty           , attrib        , 
         uom           , active        , who_entered   , 
         bench_stock   , eff_date      , date_entered  , 
         conv_factor   , constrain     , fixed         , 
         alt_seq_no    , note          , note2         , 
         note3         , note4         , plan_pcs      , 
         lag_qty       , cost_pct      , location      ,
         pool_qty
      FROM what_part
      WHERE asm_no=@pn
      select @pn=isnull( (select min(part_no) from inserted where part_no>@pn), '' )
   end 
end
END

GO
CREATE UNIQUE CLUSTERED INDEX [inv_rev1] ON [dbo].[inv_revisions] ([part_no], [revision]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_revisions] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_revisions] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_revisions] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_revisions] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_revisions] TO [public]
GO
