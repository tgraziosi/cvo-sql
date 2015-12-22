SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[fs_cycle_cnt] @loc varchar(10)  AS

set nocount on

declare @cycle_days int, @cycle_type varchar(10)
declare @x int, @chk_date datetime, @rcnt int
declare @method varchar(30)

select @method = value_str
	from config
	where flag = 'CYCLE_CNT_BY'
if @method is null
begin
   select @method = 'ITEM'
end

if @method <> 'GROUP'
begin
   select @method = 'ITEM'
end



create table #tlist
   ( cycle_type varchar(10), location varchar(10), part varchar(30), 
   description varchar(255) NULL, uom char(2) NULL, cycle_date datetime NULL, 			-- PNK 9/16/99 SCR 70 20779
   bin varchar(12) NULL, qty decimal(20,8), hold_qty decimal(20,8), lb_tracking char(1),rank_class varchar(1) )		-- PNK 9/16/99 SCR 70 20779
UPDATE cycle_types set cycle_flag='N'

UPDATE cycle_types set cycle_flag='Y' where cycle_days<=0

select @x=count(*) from cycle_types where cycle_flag='N' AND 
       ( void='N' OR void is null )
WHILE @x > 0
BEGIN
   set rowcount 1
   SELECT @cycle_type=kys, @cycle_days=( -1 * cycle_days ), @rcnt=num_items
	   FROM   cycle_types 
	   WHERE  cycle_flag='N' AND ( void='N' OR void is null )

   SELECT @chk_date=DateAdd( Day, @cycle_days, getdate() )
   if @rcnt is null 
   begin
      SELECT @rcnt = 0
   end

   select @chk_date=DateName(yy, @chk_date)+'-'+DateName(mm, @chk_date)+'-'+DateName(dd, @chk_date)+' 23:59:59'

   set rowcount @rcnt

   if @method = 'ITEM'
   begin

      INSERT #tlist
      SELECT @cycle_type, i.location, i.part_no, i.description, i.uom, i.cycle_date, i.bin_no,
	 i.in_stock, isnull(i.hold_qty+i.hold_rcv+i.hold_mfg+i.hold_ord+i.hold_xfr,0), i.lb_tracking,i.rank_class	-- PNK 9/16/99 SCR 70 20779
      FROM   #inventory i
      WHERE   i.cycle_type=@cycle_type AND                                                            --i.location=@loc AND
             isnull(i.cycle_date,'1/1/1900') <=@chk_date AND				-- mls 12/11/02 SCR 30428
             i.status<'V' AND i.status<>'R' and (i.void is null or i.void<>'V')
   end

   if @method = 'GROUP'
   begin
	

      INSERT #tlist
      SELECT @cycle_type, i.location, i.part_no, i.description, i.uom, i.cycle_date, i.bin_no,
	 i.in_stock, isnull(i.hold_qty+i.hold_rcv+i.hold_mfg+i.hold_ord+i.hold_xfr,0), i.lb_tracking,i.rank_class	-- PNK 9/16/99 SCR 70 20779
      FROM   #inventory i, category c
      WHERE   i.category=c.kys AND                                                                         --i.location=@loc AND
             c.cycle_type=@cycle_type AND isnull(i.cycle_date,'1/1/1900')<=@chk_date AND	-- mls 12/11/02 SCR 30428
             i.status<'V' AND i.status<>'R' and (i.void is null or i.void<>'V')
   end

   set rowcount 0
   UPDATE cycle_types SET cycle_flag='Y'
 	  WHERE  kys=@cycle_type

   set rowcount 0
   select @x=count(*) from cycle_types where cycle_flag='N' AND 
          ( void='N' OR void is null )
END
create table #tcycle
	( cycle_type varchar(10), location varchar(10), part varchar(30), 
	 description varchar(255) NULL, uom varchar(2) NULL, cycle_date datetime NULL, 			-- PNK 9/16/99 SCR 70 20779
	 lot varchar(25) NULL, bin varchar(12) NULL, qty decimal(20,8), hold_qty decimal(20,8),rank_class varchar(1))	-- PNK 9/16/99 SCR 70 20779



INSERT #tcycle
	SELECT t.cycle_type, t.location, t.part, t.description, t.uom, 
	       t.cycle_date, '', t.bin, t.qty, t.hold_qty,t.rank_class
	FROM   #tlist t
	WHERE  t.lb_tracking='N'



INSERT #tcycle
	SELECT t.cycle_type, t.location, t.part, t.description, t.uom, 
	       t.cycle_date, l.lot_ser, l.bin_no, l.qty, 0,t.rank_class
	FROM   #tlist t, lot_bin_stock l
	WHERE  t.part=l.part_no AND l.location=t.location AND t.lb_tracking='Y'         --l.location=@loc



INSERT #tcycle
	SELECT t.cycle_type, t.location, t.part, t.description, t.uom, 
	       t.cycle_date, '', '', 0, 0,t.rank_class
	FROM   #tlist t
	WHERE  t.lb_tracking='Y' AND
           NOT Exists ( select * from #tcycle where #tcycle.part=t.part and
	   #tcycle.location=t.location  )                                                  --and t.location=@loc

UPDATE #tcycle
	SET hold_qty=hold_qty + isnull((select sum(l.qty) 						-- PNK 9/16/99 SCR 70 20779
	  from lot_bin_ship l (nolock), orders_all o (nolock)						-- mls 11/11/99 SCR 70 21707
	 Where l.tran_no = o.order_no and l.tran_ext = o.ext and					-- mls 11/11/99 SCR 70 21707
	  t.part=l.part_no and t.location = l.location and
	  t.lot = l.lot_ser and t.bin = l.bin_no and 
	  o.status<'S'),0)										-- mls 11/11/99 SCR 70 21707		
from #tcycle t 	-- PNK 9/16/99 SCR 70 20779


--UPDATE #tcycle
--SET hold_qty=hold_qty + isnull((select sum(qty) from lot_bin_recv				-- PNK 9/16/99 SCR 70 20779
--	 Where #tcycle.part=lot_bin_recv.part_no and lot_bin_recv.location=@loc and 
-- #tcycle.location=lot_bin_recv.location and #tcycle.lot=lot_bin_recv.lot_ser and 
--	 #tcycle.bin=lot_bin_recv.bin_no and 
--	 lot_bin_recv.tran_code<'R'),0)								-- PNK 9/16/99 SCR 70 20779




UPDATE #tcycle
	SET hold_qty=hold_qty + isnull((select sum(l.qty) 						-- PNK 9/16/99 SCR 70 20779
		from lot_bin_xfer l (nolock), xfers_all x (nolock)						-- mls 11/11/99 SCR 70 21707
	 Where l.tran_no = x.xfer_no and								-- mls 11/11/99 SCR 70 21707
	   t.part=l.part_no and t.location = l.location and
	   t.lot=l.lot_ser and t.bin=l.bin_no and 
	   x.status<'R'),0)										-- mls 11/11/99 SCR 70 21707
	   from #tcycle t					-- PNK 9/16/99 SCR 70 20779							

UPDATE #tcycle
	SET hold_qty=hold_qty + isnull((select sum(l.qty) 						-- PNK 9/16/99 SCR 70 20779
	  from lot_bin_prod l (nolock), produce_all p (nolock)						-- mls 11/11/99 SCR 70 21707
	  Where l.tran_no = p.prod_no and l.tran_ext = p.prod_ext  and					-- mls 11/11/99 SCR 70 21707
	    t.part=l.part_no and t.location=l.location and t.lot=l.lot_ser and 
	    t.bin=l.bin_no and p.status <'S'),0)							-- mls 11/11/99 SCR 70 21707
		from #tcycle t										-- PNK 9/16/99 SCR 70 20779


UPDATE #tcycle
	SET hold_qty=hold_qty + isnull((select sum(qc_qty) from qc_results q				-- PNK 9/16/99 SCR 70 20779
	  Where t.part=q.part_no and 
	    t.location=q.location and t.lot=q.lot_ser and 
	    t.bin=q.bin_no and 
	    q.status <'S'),0)										-- PNK 9/16/99 SCR 70 20779
	from #tcycle t											-- mls 11/11/99 SCR 70 21707



INSERT #tcycle
	SELECT t.cycle_type, t.location, t.part, t.description, t.uom, 
	 t.cycle_date, l.lot_ser, l.bin_no, 0, l.qty,t.rank_class
	FROM #tlist t, lot_bin_ship l (nolock), orders_all o (nolock)					-- mls 11/11/99 SCR 70 21707
	WHERE l.tran_no = o.order_no and l.tran_ext = o.ext and						-- mls 11/11/99 SCR 70 21707
	  t.part=l.part_no AND l.location=t.location AND t.lb_tracking='Y' AND o.status < 'S' and	--AND l.location=@loc	-- mls 11/11/99 SCR 70 21707
	  NOT Exists ( select * from #tcycle where #tcycle.part=l.part_no and
		 #tcycle.location=l.location and #tcycle.lot=l.lot_ser and
		 #tcycle.bin=l.bin_no)

















INSERT #tcycle
	SELECT t.cycle_type, t.location, t.part, t.description, t.uom, 
	 t.cycle_date, l.lot_ser, l.bin_no, 0, l.qty,t.rank_class
	FROM #tlist t, lot_bin_xfer l (nolock), xfers_all x (nolock)					-- mls 11/11/99 SCR 70 21707
	WHERE l.tran_no = x.xfer_no and x.status < 'R' and 						-- mls 11/11/99 SCR 70 21707
  t.part=l.part_no AND l.location=t.location AND t.lb_tracking='Y' AND                       --l.location=@loc
	  NOT Exists ( select * from #tcycle where #tcycle.part=l.part_no and
		 #tcycle.location=l.location and #tcycle.lot=l.lot_ser and
		 #tcycle.bin=l.bin_no)



INSERT #tcycle
	SELECT t.cycle_type, t.location, t.part, t.description, t.uom, 
	 t.cycle_date, l.lot_ser, l.bin_no, 0, l.qty,t.rank_class
	FROM #tlist t, lot_bin_prod l (nolock), produce_all p (nolock)					-- mls 11/11/99 SCR 70 21707
	WHERE l.tran_no = p.prod_no and l.tran_ext = p.prod_ext and p.status < 'S' and
	  t.part=l.part_no AND l.location=t.location AND t.lb_tracking='Y' AND                --l.location=@loc
	   NOT Exists ( select * from #tcycle where #tcycle.part=l.part_no and
		 #tcycle.location=l.location and #tcycle.lot=l.lot_ser and
		 #tcycle.bin=l.bin_no )

update inv_list set cycle_date=GetDate()
	from inv_list, #tcycle where
	inv_list.part_no=#tcycle.part and
	inv_list.location=#tcycle.location    --RLT LOTSER 5/10/00



SELECT cycle_type, location, part, description, uom, 
	cycle_date, lot, bin, qty, hold_qty,rank_class						-- mls 10/5/01 SCR 27718
FROM   #tcycle
ORDER BY location, part, bin, lot

GO
GRANT EXECUTE ON  [dbo].[fs_cycle_cnt] TO [public]
GO
