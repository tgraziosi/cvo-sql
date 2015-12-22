SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_agent] @part varchar(30), @src char(1), 
                          @src_no int,       @src_date datetime,
                          @who varchar(20),  @src_qty decimal(20,8) AS


declare @msg varchar(100)
declare @mode char(1), @verb varchar(10), @obj varchar(255)
declare @x int, @loc varchar(10), @tpart varchar(30)
declare @stat char(1), @xmode varchar(10), @xpart varchar(30)
declare @loc2 varchar(10), @tqty decimal(20,8)
declare @prodno int, @prodext int, @seqno varchar(4)
declare @pono varchar(16), @tno int
declare @planpcs decimal(20,8), @lb char(1), @lot varchar(25)
declare @bin varchar(12), @expdate datetime, @xlp int

DECLARE @qc_flag char(1)									-- mls 2/26/01 SCR 26061

select @lb = 'N'

SELECT @mode =
CASE WHEN @src = 'B' THEN @src 

     WHEN @src = 'R' THEN @src 
     ELSE 'Z' 
END







select @who = @who + ' via agent'

if @mode = 'Z' begin
   raiserror 69910 'Invalid Agent!'
   return -1
   end

select @prodno = 0
if @mode = 'B' begin
   select @loc  = location from purchase_all where po_key=@src_no
   select @loc2 = ship_to_no from purchase_all where po_key=@src_no
   end
   select @prodno = isnull( (select prod_no from purchase_all where po_key=@src_no), 0 )
   if @prodno > 0 begin
      select @prodext = isnull( (select prod_ext from produce_all 
                                 where prod_no=@prodno and status < 'R'), 0)
   end
if @mode = 'P' begin
   select @loc  = location from produce_all where prod_no=@src_no
   end
if @mode = 'R' begin
   select @pono = po_no, @lb = lb_tracking
          from receipts_all where receipt_no=@src_no
   select @loc  = location from receipts_all where receipt_no=@src_no
   select @loc2 = p.location 
          from receipts_all r, purchase_all p
          where r.po_no=p.po_no and r.receipt_no=@src_no
   select @prodno = isnull( (select prod_no from purchase_all where po_no=@pono), 0 )
   if @prodno > 0 begin
      select @prodext = isnull( (select prod_ext from produce_all 
                                 where prod_no=@prodno and status < 'R'), 0)
   end
end





if @src_qty < 0 begin
   select @x = isnull( (select max(seq_no) from agents
               where part_no = @part and
               agent_type = @mode ), 0 )
   end
else begin
   select @x = isnull( (select min(seq_no) from agents
               where part_no = @part and
               agent_type = @mode ), 0 )
   end
while @x > 0 begin
   select @tqty = @src_qty
   select @verb = agent_verb, @obj = agent_obj

          from agents 
          where part_no = @part and agent_type = @mode and
          seq_no = @x










   if @verb = 'PRODUCE' begin
      if @lb = 'N' or @mode <> 'R' begin
         select @tpart = @obj

         if @obj = ':ITEM' begin

            select @tpart = @part
         end

	 select @qc_flag = isnull((select qc_flag from inv_master where part_no = @tpart),'N')	-- mls 2/26/01 SCR 26061

         select @tqty  = isnull( (select @src_qty / qty from what_part 
                                  where asm_no=@tpart and
                                  part_no=@part and active<'C'  and 
	     ( what_part.location = @loc OR what_part.location = 'ALL' )),@src_qty)

         insert prod_batch (prod_no,     prod_ext,    status,     part_no, 

                            location,    prod_date,   qty,        lot_ser, 
                            bin_no,      project_key, batch_type, qc_flag,
                            who_entered, date_expires)
         select 0,        0,           case when @qc_flag = 'N' then 'S' else 'R' end,     @tpart,	-- mls 2/26/01 SCR 26061 

                @loc,     getdate(),   @tqty,   'N/A', 
                'N/A',    'N/A',       'G',     m.qc_flag,
                @who,     getdate()
	        from inv_master m where
	        m.part_no=@tpart
      end
      if @lb = 'Y' and @mode = 'R' begin
         select @tpart = @obj
         if @obj = ':ITEM' begin

            select @tpart = @part
         end
         select @xlp = Isnull( (select min(row_id) from lot_bin_recv
                                where tran_no=@src_no),0)
         while @xlp > 0 begin
            select @lot=lot_ser, @bin=bin_no, 
                   @expdate=date_expires, @tqty=qty 
                   from lot_bin_recv
                   where tran_no=@src_no and row_id=@xlp
            select @tqty  = isnull( (select @tqty / qty from what_part 
                                     where asm_no=@tpart and
                                     part_no=@part and active<'C'  and 
	           ( what_part.location = @loc OR what_part.location = 'ALL' )),@src_qty)

            insert prod_batch (prod_no,    prod_ext,     status,     part_no, 

                               location,   prod_date,    qty,        lot_ser, 
                               bin_no,     date_expires, project_key, 
                               batch_type, qc_flag,      who_entered )
            select 0,        0,           'S',     @tpart, 

                   @loc,     getdate(),   @tqty,   @lot, 
                   @bin,     @expdate,    'N/A',       
                   'G',      m.qc_flag,   @who
   	           from inv_master m where
	           m.part_no=@tpart

            select @xlp = Isnull( (select min(row_id) from lot_bin_recv
                                   where tran_no=@src_no and row_id>@xlp),0)

         end
      end

   end

   if @verb = 'WIP' and @prodno > 0 begin
      if @lb = 'N' begin
         UPDATE next_time_no SET last_no = last_no + 1
         WHERE  last_no = last_no

         SELECT @tno = last_no from next_time_no

         WHERE  last_no = last_no

         SELECT @seqno = isnull( (select seq_no from prod_list
                                 where prod_no = @prodno and 
                                       part_no = @part), 'ERR!' )

         if @seqno = 'ERR!' begin

            return -3
         end
         SELECT @planpcs = 1
         SELECT @planpcs = plan_pcs / plan_qty

                from prod_list
                where prod_no = @prodno and 
                      part_no = @part and plan_qty <> 0


          INSERT prod_use (
                time_no        , employee_key   , prod_no        , 
                prod_ext       , prod_part      , location       , 
                seq_no         , part_no        , project_key    , 
                status         , tran_date      , plan_qty       , 
                used_qty       , plan_pcs       , pieces         , 
                shift          , who_entered    , date_entered   , 
                note           , scrap_pcs      , lot_ser        , 
                bin_no                                              )
         SELECT @tno           , @who           , @prodno        , 
                @prodext       , part_no        , location       , 
                @seqno         , @part          , project_key    , 
                'P'            , getdate()      , 0              , 
                @src_qty       , 0              , @src_qty*@planpcs      , 
                0              , @who           , getdate()      , 
                null           , 0              , null           , 
                null
         FROM   produce_all
         WHERE  produce_all.prod_no=@prodno  
      end
      if @lb = 'Y' begin
         SELECT @seqno = isnull( (select seq_no from prod_list
                                 where prod_no = @prodno and 
                                       part_no = @part), 'ERR!' )
         if @seqno = 'ERR!' begin
            return -3
         end
         SELECT @planpcs = 1
         SELECT @planpcs = plan_pcs / plan_qty

                from prod_list
                where prod_no = @prodno and 
                      part_no = @part and plan_qty <> 0

         select @xlp = Isnull( (select min(row_id) from lot_bin_recv
                                where tran_no=@src_no),0)

        While @xlp > 0 begin
            select @lot=lot_ser, @bin=bin_no, 
                   @expdate=date_expires, @tqty=qty 
                   from lot_bin_recv
                   where tran_no=@src_no and row_id=@xlp



            UPDATE next_time_no SET last_no = last_no + 1
            WHERE  last_no = last_no

            SELECT @tno = last_no from next_time_no
            WHERE  last_no = last_no

             INSERT prod_use (
                   time_no        , employee_key   , prod_no        , 
                   prod_ext       , prod_part      , location       , 
                   seq_no         , part_no        , project_key    , 
                   status         , tran_date      , plan_qty       , 
                   used_qty       , plan_pcs       , pieces         , 
                   shift          , who_entered    , date_entered   , 
                   note           , scrap_pcs      , lot_ser        , 
                   bin_no                                              )
            SELECT @tno           , @who           , @prodno        , 
                   @prodext       , part_no        , location       , 
                   @seqno         , @part          , project_key    , 
                   'P'            , getdate()      , 0              , 
                   @tqty          , 0              , @tqty*@planpcs  , 
                   0              , @who           , getdate()      , 
                   null           , 0              , @lot           , 
                   @bin
            FROM   produce_all
            WHERE  produce_all.prod_no=@prodno  
            select @xlp = Isnull( (select min(row_id) from lot_bin_recv
                                   where tran_no=@src_no and row_id>@xlp),0)
         end
      end
   end


   if @verb = 'XFER' or @verb = 'AUTOXFER' or @verb = 'OUTSOURCE' begin
      select @xmode = ''
      select @xpart = ''
      select @tpart = @obj
      select @stat  = 'N'
      if @obj = ':ITEM' begin
         select @tpart = @part
      end
      if substring(@obj,1,10) = ':BUILDPLAN' or @verb = 'OUTSOURCE' begin
         select @xmode = 'BUILDPLAN'
      end
      if @verb = 'OUTSOURCE' begin

         select @xpart = @part
      end
      if substring(@obj,1,11) = ':BUILDPLAN=' begin
         select @tpart = substring(@obj,12,30)
      end
      if @verb = 'AUTOXFER' begin
         select @stat = 'S'
      end
      select @tqty  = isnull( (select @src_qty / qty from what_part 
                               where asm_no=@tpart and
                               part_no=@part and active<'C'),@src_qty)

      exec fs_auto_xfer @loc, @loc2, @tpart, @tqty,     
                        @xpart, @stat, @xmode, @who

   end

   if @src_qty < 0 begin
      select @x = isnull( (select max(seq_no) from agents
                  where part_no = @part and
                  agent_type = @mode and seq_no < @x ), 0 )
      end
   else begin
      select @x = isnull( (select min(seq_no) from agents
                  where part_no = @part and
                  agent_type = @mode and seq_no > @x ), 0 )
      end
end
return 1

GO
GRANT EXECUTE ON  [dbo].[fs_agent] TO [public]
GO
