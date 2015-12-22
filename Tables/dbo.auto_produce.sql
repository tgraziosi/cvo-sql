CREATE TABLE [dbo].[auto_produce]
(
[timestamp] [timestamp] NOT NULL,
[auto_no] [int] NOT NULL,
[prod_no] [int] NOT NULL,
[auto_part] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[project_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL,
[employee_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_date] [datetime] NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t500delautop] ON [dbo].[auto_produce]
 FOR DELETE 
AS
begin
if exists (select * from config where flag='TRIG_DEL_AUTO' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 76299, 'You Can Not Delete An AUTO_PRODUCE Record!' 
	return
	end
end

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insautop] ON [dbo].[auto_produce] 
 FOR INSERT 
AS
BEGIN

   UPDATE inv_produce set produced_mtd = produced_mtd + ref.qty,
		produced_ytd = produced_ytd + ref.qty
     FROM inserted ref
    WHERE ref.auto_part=inv_produce.part_no and
          ref.location=inv_produce.location
   INSERT lot_bin_tran (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext,
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who)
   SELECT ref.location, ref.auto_part, 'WIP', ref.lot_ser,
          'A', ref.auto_no, 0, ref.tran_date, ref.tran_date, 
          qty, 1, i.avg_cost, 'NA', 0, 0, 0, ref.who_entered
     FROM inserted ref,inventory i
    WHERE ref.auto_part=i.part_no and 
          ref.location=i.location and i.lb_tracking='Y'

   UPDATE inv_produce
      SET usage_mtd=inv_produce.usage_mtd + (w.qty * ref.qty),
          usage_ytd=inv_produce.usage_ytd + (w.qty * ref.qty) 
     FROM what_part w, inserted ref, inventory i
    WHERE (w.asm_no=ref.auto_part) and
          (w.part_no= inv_produce.part_no) and
          (inv_produce.location=ref.location) and
          (w.part_no= i.part_no) and
          (i.location=ref.location) and
          w.active<'C' and w.constrain='Y' and
	  w.part_no=i.part_no and 
	   ref.location=i.location and 	
          i.status <> 'R'
   INSERT lot_bin_tran (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext,
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who)
   SELECT ref.location, w.part_no, 'WIP', ref.lot_ser,
          'A', ref.auto_no, 0, ref.tran_date, ref.tran_date, 
          (w.qty * ref.qty), (-1), i.avg_cost, 
          'NA', 0, 0, 0, ref.who_entered
     FROM what_part w, inserted ref, inventory i
    WHERE (w.asm_no=ref.auto_part) and
          (w.part_no= i.part_no) and
          (i.location=ref.location) and
          w.active<'C' and w.constrain='Y' and
          i.status<>'R' and i.lb_tracking='Y'
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updautop] ON [dbo].[auto_produce] 
 FOR UPDATE
AS
BEGIN
   UPDATE inv_produce set produced_mtd= produced_mtd + ref.qty,
		produced_ytd= produced_ytd + ref.qty
     FROM inserted ref
    WHERE ref.auto_part=inv_produce.part_no and
          ref.location=inv_produce.location
   INSERT lot_bin_tran (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext,
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who)
   SELECT ref.location, ref.auto_part, 'WIP', ref.lot_ser,
          'A', ref.auto_no, 0, ref.tran_date, ref.tran_date, 
          qty, 1, i.avg_cost, 'NA', 0, 0, 0, ref.who_entered
     FROM inserted ref,inventory i
    WHERE ref.auto_part=i.part_no and 
          ref.location=i.location and i.lb_tracking='Y'
    
   UPDATE inv_produce
      SET usage_mtd=inv_produce.usage_mtd + (w.qty * ref.qty),
          usage_ytd=inv_produce.usage_ytd + (w.qty * ref.qty) 
     FROM what_part w, inserted ref, inventory i
    WHERE (w.asm_no=ref.auto_part) and
          (w.part_no= inv_produce.part_no) and
          (inv_produce.location=ref.location) and
          (i.location=ref.location) and
          (w.part_no= i.part_no) and
          w.active<'C' and w.constrain='Y' and
          i.status<>'R'
   INSERT lot_bin_tran (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext,
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who)
   SELECT ref.location, w.part_no, 'WIP', ref.lot_ser,
          'A', ref.auto_no, 0, ref.tran_date, ref.tran_date, 
          (w.qty * ref.qty), (-1), i.avg_cost, 
          'NA', 0, 0, 0, ref.who_entered
     FROM what_part w, inserted ref, inventory i
    WHERE (w.asm_no=ref.auto_part) and
          (w.part_no= i.part_no) and
          (i.location=ref.location) and
          w.active<'C' and w.constrain='Y' and
          i.status<>'R' and i.lb_tracking='Y'

   UPDATE inv_produce set produced_mtd=produced_mtd - ref.qty,
		produced_ytd= produced_ytd - ref.qty
     FROM deleted ref
    WHERE ref.auto_part=inv_produce.part_no and
          ref.location=inv_produce.location
   INSERT lot_bin_tran (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext,
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who)
   SELECT ref.location, ref.auto_part, 'WIP', ref.lot_ser,
          'A', ref.auto_no, 0, ref.tran_date, ref.tran_date, 
          qty, 1, i.avg_cost, 'NA', 0, 0, 0, ref.who_entered
     FROM deleted ref,inventory i
    WHERE ref.auto_part=i.part_no and 
          ref.location=i.location and i.lb_tracking='Y'
   INSERT lot_bin_tran (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext,
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who)
   SELECT ref.location, ref.auto_part, 'WIP', ref.lot_ser,
          'A', ref.auto_no, 0, ref.tran_date, ref.tran_date, 
          qty, -1, i.avg_cost, 'NA', 0, 0, 0, ref.who_entered
     FROM deleted ref,inventory i
    WHERE ref.auto_part=i.part_no and 
          ref.location=i.location and i.lb_tracking='Y'
    
   UPDATE inv_produce
      SET usage_mtd=inv_produce.usage_mtd - (w.qty * ref.qty),
          usage_ytd=inv_produce.usage_ytd - (w.qty * ref.qty) 
     FROM what_part w, deleted ref, inventory i
    WHERE (w.asm_no=ref.auto_part) and
          (w.part_no= inv_produce.part_no) and
          (inv_produce.location=ref.location) and
          (i.location=ref.location) and
          (w.part_no= i.part_no) and
          w.active<'C' and w.constrain='Y' and
          i.status<>'R'
   INSERT lot_bin_tran (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext,
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who)
   SELECT ref.location, w.part_no, 'WIP', ref.lot_ser,

          'A', ref.auto_no, 0, ref.tran_date, ref.tran_date, 
          (w.qty * ref.qty), (-1), i.avg_cost, 
          'NA', 0, 0, 0, ref.who_entered
     FROM what_part w, deleted ref, inventory i
    WHERE (w.asm_no=ref.auto_part) and
          (w.part_no= i.part_no) and
          (i.location=ref.location) and
          (w.part_no= i.part_no) and
          (i.location=ref.location) and
          w.active<'C' and w.constrain='Y' and
          i.status<>'R' and i.lb_tracking='Y'
END

GO
CREATE UNIQUE CLUSTERED INDEX [autoprd1] ON [dbo].[auto_produce] ([auto_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[auto_produce] TO [public]
GO
GRANT SELECT ON  [dbo].[auto_produce] TO [public]
GO
GRANT INSERT ON  [dbo].[auto_produce] TO [public]
GO
GRANT DELETE ON  [dbo].[auto_produce] TO [public]
GO
GRANT UPDATE ON  [dbo].[auto_produce] TO [public]
GO
