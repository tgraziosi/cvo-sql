SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_auto_recv] @no int, @part varchar(30), 
                              @rdate datetime, @who varchar(10) AS

begin
declare @rno int

update next_rec_no set last_no=last_no
select @rno=last_no from next_rec_no
CREATE TABLE #treceipts (
	receipt_no int NOT NULL ,           po_no varchar (16) NOT NULL ,
	part_no varchar (30) NOT NULL ,     sku_no varchar (30) NULL ,
	location varchar (10) NOT NULL ,    release_date datetime NOT NULL ,
	recv_date datetime NOT NULL ,       part_type varchar (10) NULL ,
	unit_cost decimal(20, 8) NOT NULL , quantity decimal(20, 8) NOT NULL ,
	vendor varchar (10) NOT NULL ,      unit_measure char (2) NULL ,
	prod_no int NULL ,                  freight_cost decimal(20, 8) NOT NULL ,
	account_no varchar (32) NULL ,      status char (1) NOT NULL ,
	ext_cost decimal(20, 8) NOT NULL ,  who_entered varchar (20) NULL ,
	vend_inv_no varchar (20) NULL ,     conv_factor decimal(20, 8) NOT NULL ,
	pro_number varchar (20) NULL ,      bl_no int NULL ,
	lb_tracking char (1) NULL ,         freight_flag char (1) NULL ,
	freight_vendor varchar (10) NULL ,  freight_inv_no varchar (20) NULL ,
	freight_account varchar (32) NULL , freight_unit decimal(20, 8) NOT NULL ,
	voucher_no varchar (16) NULL ,      note varchar (255) NULL ,
	po_key int NULL ,                   qc_flag char (1) NULL ,
	qc_no int NULL ,                    rejected decimal(20, 8) NULL,
	po_line int NOT NULL,										-- mls 5/15/01 SCR 6603
        row_id int identity(1,1)    )
insert #treceipts (
       receipt_no       , po_no            , part_no          , 
       sku_no           , location         , release_date     , 
       recv_date        , part_type        , unit_cost        , 
       quantity         , vendor           , unit_measure     , 
       prod_no          , freight_cost     , account_no       , 
       status           , ext_cost         , who_entered      , 
       vend_inv_no      , conv_factor      , pro_number       , 
       bl_no            , lb_tracking      , freight_flag     , 
       freight_vendor   , freight_inv_no   , freight_account  , 
       freight_unit     , voucher_no       , note             , 
       po_key           , qc_flag          , qc_no            , 
       rejected,
       po_line    )											-- mls 5/15/01 SCR 6603
       select
       @rno             , p.po_no          , l.part_no          , 
       l.vend_sku       , l.location       , r.release_date     , 
       getdate()        , l.type           , l.unit_cost        , 
       r.quantity       , p.vendor_no      , l.unit_measure     , 
       0                , 0                , l.account_no       , 
       'R'              , 0                , @who      , 
       null             , l.conv_factor    , null       , 
       0                , l.lb_tracking    , 'N'     , 
       null             , null             , null  , 
       0                , null             , null             , 
       p.po_key         , 'N'              , 0            , 
       0   ,
       l.line												-- mls 5/15/01 SCR 6603
       from purchase_all p, pur_list l, releases r
       where p.po_key  = l.po_key and 
             p.po_key  = r.po_key and 
             l.part_no = r.part_no and 
             l.line = case when isnull(r.po_line,0)=0 then l.line else r.po_line end and			-- mls 5/15/01 SCR 6603
             p.po_key  = @no and
             r.release_date = @rdate and
             l.part_no like @part and r.status='O'
update #treceipts set receipt_no = receipt_no + row_id
update #treceipts set qc_flag = i.qc_flag
       from inv_master i
       where #treceipts.part_no=i.part_no
select @rno=max( receipt_no ) from #treceipts
insert receipts_all (
       receipt_no       , po_no            , part_no          , 
       sku_no           , location         , release_date     , 
       recv_date        , part_type        , unit_cost        , 
       quantity         , vendor           , unit_measure     , 
       prod_no          , freight_cost     , account_no       , 
       status           , ext_cost         , who_entered      , 
       vend_inv_no      , conv_factor      , pro_number       , 
       bl_no            , lb_tracking      , freight_flag     , 
       freight_vendor   , freight_inv_no   , freight_account  , 
       freight_unit     , voucher_no       , note             , 
       po_key           , qc_flag          , qc_no            , 
       rejected ,
       po_line   )											-- mls 5/15/01 SCR 6603
       select
       receipt_no       , po_no          , part_no          , 
       sku_no           , location       , release_date     , 
       getdate()        , part_type      , unit_cost        , 
       quantity         , vendor         , unit_measure     , 
       0                , 0              , account_no       , 
       'R'              , 0              , @who      , 
       null             , conv_factor    , null       , 
       0                , lb_tracking    , 'N'     , 
       null             , null           , null  , 
       0                , null           , null             , 
       po_key           , 'N'            , 0            , 
       0   ,
       po_line												-- mls 5/15/01 SCR 6603
       from #treceipts
insert lot_bin_recv (
       location     , part_no      , bin_no       , 
       lot_ser      , tran_code    , tran_no      , 
       tran_ext     , date_tran    , date_expires , 
       qty          , direction    , cost         , 
       uom          , uom_qty      , conv_factor  , 
       line_no      , who          , qc_flag      ) 
       select
       location     , part_no      , 'N/A'      , 
       'N/A'        , 'R'          , receipt_no      , 
       0            , getdate()    , getdate() , 
       (quantity*conv_factor) , 1  , unit_cost         , 
       unit_measure , quantity     , conv_factor  , 
       0            , @who         , qc_flag      
       from #treceipts where #treceipts.lb_tracking='Y'
update next_rec_no set last_no=@rno

END

GO
GRANT EXECUTE ON  [dbo].[fs_auto_recv] TO [public]
GO
