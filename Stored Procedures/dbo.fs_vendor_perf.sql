SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[fs_vendor_perf] @vend varchar(12),
                 @bdate datetime, @edate datetime AS
BEGIN

  create table #temprec
	 ( vendor_code varchar(12), vendor_name varchar(30), release_date datetime,
	   recv_date datetime,     receipt_no integer,      po_no varchar(10),
	   part_no varchar(30),    status char(1),          rcv_qty money,
	   rtv_qty money,          scr_qty money,           bdate datetime,
      edate datetime,         vend varchar(12)                                 ) -- mls 1/23/02 SCR 28218
  INSERT #temprec
       ( vendor_code , vendor_name , release_date ,
	      recv_date ,  receipt_no ,  po_no ,
	      part_no ,    status ,      rcv_qty ,
	      rtv_qty ,    scr_qty ,     bdate ,
              edate ,      vend                      )
  SELECT dbo.adm_vend_all.vendor_code ,
         dbo.adm_vend_all.vendor_name ,
         receipts_all.release_date ,
         receipts_all.recv_date ,
         receipts_all.receipt_no ,
         receipts_all.po_no ,
         receipts_all.part_no ,
         receipts_all.status ,
         receipts_all.quantity ,
         0 ,
         receipts_all.rejected ,
         @bdate ,
         @edate ,
         @vend
    FROM dbo.adm_vend_all,
         receipts_all
   WHERE ( dbo.adm_vend_all.vendor_code = receipts_all.vendor ) AND
         ( dbo.adm_vend_all.vendor_code like @vend ) AND
         ( receipts_all.release_date >= @bdate ) AND
         ( receipts_all.release_date <= @edate ) AND receipts_all.quantity>0
  SELECT vendor_code , vendor_name , release_date ,
         recv_date ,  receipt_no ,  po_no ,
         part_no ,    status ,      rcv_qty ,
         rtv_qty ,    scr_qty ,     bdate ,
         edate ,      vend
  FROM  #temprec
  ORDER BY release_date ASC, vendor_code ASC
End

GO
GRANT EXECUTE ON  [dbo].[fs_vendor_perf] TO [public]
GO
