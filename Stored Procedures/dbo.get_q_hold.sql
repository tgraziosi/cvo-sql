SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_hold] @pn varchar(30), @loc varchar(10), @lot varchar(25), @bin varchar(12)  AS

create table #tlot
	( tran_code char(1), tran_no int, tran_ext int, part_no varchar(30), location varchar(10), 
     bin_no varchar(12) NULL, lot_ser varchar(25) NULL, date_expires datetime NULL, qty money )
INSERT #tlot
SELECT 'C', l.tran_no, l.tran_ext, l.part_no, l.location,   
       l.bin_no, l.lot_ser, l.date_expires, l.qty
FROM lot_bin_ship  l (nolock), orders_all o (nolock)					-- mls 4/21/00 SCR 70 21707
WHERE l.tran_no = o.order_no and l.tran_ext = o.ext 					-- mls 4/21/00 SCR 70 21707
  and ( l.part_no = @pn ) AND  
      ( l.location = @loc ) AND
      ( l.lot_ser like @lot ) AND
      ( l.bin_no like @bin )  AND
      ( o.status < 'S' )								-- mls 4/21/00 SCR 70 21707  
ORDER BY date_expires, bin_no ASC, lot_ser ASC   

INSERT #tlot
SELECT 'T', l.tran_no, l.tran_ext, l.part_no, l.location,   				-- mls 4/21/00 SCR 21707 start
       l.bin_no, l.lot_ser, l.date_expires, l.qty
FROM lot_bin_xfer l (nolock), xfers_all x (nolock)
WHERE l.tran_no = x.xfer_no and
      ( l.part_no = @pn ) AND  
      ( l.location = @loc ) AND
      ( l.lot_ser like @lot ) AND
      ( l.bin_no like @bin )  AND
      ( x.status < 'R' )  								-- mls 4/21/00 SCR 21707 end
ORDER BY date_expires, bin_no ASC, lot_ser ASC   

INSERT #tlot
SELECT 'P', l.tran_no, l.tran_ext, l.part_no, l.location,   				-- mls 4/21/00 SCR 21707 start
       l.bin_no, l.lot_ser, l.date_expires, l.qty
FROM lot_bin_prod l (nolock), produce_all p (nolock)
WHERE l.tran_no = p.prod_no and l.tran_ext = p.prod_ext and
      ( l.part_no = @pn ) AND  
      ( l.location = @loc ) AND
      ( l.lot_ser like @lot ) AND
      ( l.bin_no like @bin )  AND
      ( p.status < 'S' )  								-- mls 4/21/00 SCR 21707 end
ORDER BY date_expires, bin_no ASC, lot_ser ASC   



SELECT tran_code, tran_no, tran_ext, part_no, location,   
       bin_no, lot_ser, date_expires, qty
FROM  #tlot  
ORDER BY tran_code, tran_no, tran_ext, date_expires,
         bin_no ASC, lot_ser ASC

GO
GRANT EXECUTE ON  [dbo].[get_q_hold] TO [public]
GO
