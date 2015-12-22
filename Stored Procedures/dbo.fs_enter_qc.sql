SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_enter_qc]  @src  char(1), @src_no int,
		 @src_ext int, @line_no int, 
                 @pn varchar(30),  @loc varchar(10), 
                 @lot varchar(25), @bin varchar(12),
                 @qty decimal(20,8), @vend varchar(10), 
                 @who varchar(20), @rcode varchar(10), @dtexp datetime AS

declare @lb char(1), @qno int, @stat char(1)
declare @inv_lot_bin varchar(10)								-- mls
declare @in_src char(1), @rc int								-- mls

select @in_src = @src										-- mls
if @in_src = 'M'  select @src = 'P'								-- mls

if @dtexp is null select @dtexp=getdate()
if @dtexp < '1/2/1900' select @dtexp=getdate()

select @inv_lot_bin = isnull((select substring(value_str,1,1) from config (nolock)				-- mls 2/23/01 SCR 26060
  where flag = 'INV_LOT_BIN'),'N')

SELECT @qno=qc_results.qc_no, @stat=status
FROM   qc_results
WHERE  qc_results.tran_code=@src and qc_results.tran_no=@src_no and
       qc_results.ext = @src_ext and						-- mls 5/16/02 SCR 28948
       qc_results.part_no=@pn    and qc_results.location=@loc and
       qc_results.lot_ser=@lot   and qc_results.bin_no=@bin and 
       qc_results.line_no=@line_no and qc_results.status<>'A'
       and qc_results.status<>'S'						-- mls 1/19/05 SCR 31742
if @qno > 0 
begin
  if @stat='S'
  begin
   raiserror 68001 'SQL Error.  QC Record Already Released.'
   rollback tran
   return 68001
  end
  UPDATE qc_results
  SET    qc_results.qc_qty=@qty
  WHERE  qc_results.qc_no=@qno
  return 0
end

update next_qc_no
SET    next_qc_no.last_no=next_qc_no.last_no+1
if @@error <> 0
begin
   raiserror 68002 'SQL Error.  Could Not Get Next QC No.'
   rollback tran
   return 68002
end
SELECT @qno=next_qc_no.last_no
FROM   next_qc_no
if @@error<>0
begin
   raiserror 68003 'SQL Error.  Could Not Get Next QC No.'
   rollback tran
   return 68003
end
if @qno=0 OR @qno is null
begin
   raiserror 68004 'SQL Error.  Could Not Get Next QC No.'
   rollback tran
   return 68004
end

select @lb=isnull((select lb_tracking from   inv_master (nolock) where  part_no=@pn),'N')	-- mls

if @in_src != 'M' or (@lb = 'N' or (@lb = 'Y' and @inv_lot_bin = 'R'))				-- mls
begin
  INSERT qc_results
  ( qc_no          , tran_code      , tran_no        , 
  part_no        , location       , lot_ser        , 
  bin_no         , status         , qc_qty         , 
  reject_qty     , reject_reason  , vendor_key     , 
  lb_tracking    , appearance     , 
  composition    , inspector      , who_inspected  , 
  date_inspected , who_entered    , date_entered   , 
  note           , date_complete  , picture_type   , 
  picture_name   , reason 	  , ext		   ,
  line_no        , reject_type    , date_expires )
  VALUES
  ( @qno           , @src         , @src_no        ,
  @pn            , @loc           , @lot           ,
  @bin           , 'N'            , @qty           ,
  0              , null           , @vend          ,
  @lb            , null           ,
  null           , null           , null           ,
  null           , @who           , getdate()      ,
  null           , null           , null           ,
  null           , @rcode         , @src_ext       ,
  @line_no       , 'S'		  , @dtexp )

  if @@error<>0
  begin
    raiserror 68005 'SQL Error.  Could Not Insert QC record.'
    rollback tran
    return 68005
  end
  INSERT qc_detail
  ( qc_no        , part_no     , test_key     , 
  value        , coa          , print_note   , 
  pass_fail    , date_entered , who_entered  , 
  status       , note            )
  SELECT
  @qno         , @pn          , test_key     ,
  null         , coa          , print_note   ,
  'P'          , getdate()    , @who         ,
  'N'          , null        
  FROM qc_part
  WHERE qc_part.part_no=@pn
  if @@error<>0
  begin
    raiserror 68006 'SQL Error.  Could Not Insert QC Test record.'
    rollback tran
    return 68006
  end
  
  if @src='R' begin
	update receipts_all set qc_no=@qno where receipt_no=@src_no
  end
  if @src='C' begin
	update ord_list set qc_no=@qno 
		where order_no=@src_no and order_ext=@src_ext and line_no=@line_no
  end
  if @src='I' begin
	update issues_all set qc_no=@qno where issue_no=@src_no
  end
  if @src = 'P' begin
	update prod_list set qc_no=@qno where prod_no=@src_no and prod_ext=@src_ext and line_no=@line_no
  end
end
else
begin
  set rowcount 1 
  select @bin = bin_no, @lot = lot_ser, @qty = qty, @dtexp = date_expires
  from lot_bin_prod 
  where tran_no = @src_no and tran_ext = @src_ext and line_no = @line_no and
  location = @loc and part_no = @pn
  order by bin_no + '~' +  lot_ser
  select @rc = @@rowcount
  set rowcount 0

  while @rc > 0
  begin 
  INSERT qc_results
  ( qc_no          , tran_code      , tran_no        , 
  part_no        , location       , lot_ser        , 
  bin_no         , status         , qc_qty         , 
  reject_qty     , reject_reason  , vendor_key     , 
  lb_tracking    , appearance     , 
  composition    , inspector      , who_inspected  , 
  date_inspected , who_entered    , date_entered   , 
  note           , date_complete  , picture_type   , 
  picture_name   , reason 	  , ext		   ,
  line_no        , reject_type    , date_expires )
  VALUES
  ( @qno           , @src           , @src_no        ,
  @pn            , @loc           , @lot           ,
  @bin           , 'N'            , @qty           ,
  0              , null           , @vend          ,
  @lb            , null           ,
  null           , null           , null           ,
  null           , @who           , getdate()      ,
  null           , null           , null           ,
  null           , @rcode         , @src_ext       ,
  @line_no       , 'S'		  , @dtexp )

  if @@error<>0
  begin
    raiserror 68005 'SQL Error.  Could Not Insert QC record.'
    rollback tran
    return 68005
  end

  INSERT qc_detail
  ( qc_no        , part_no     , test_key     , 
  value        , coa          , print_note   , 
  pass_fail    , date_entered , who_entered  , 
  status       , note            )
  SELECT
  @qno         , @pn          , test_key     ,
  null         , coa          , print_note   ,
  'P'          , getdate()    , @who         ,
  'N'          , null        
  FROM qc_part
  WHERE qc_part.part_no=@pn
  if @@error<>0
  begin
    raiserror 68006 'SQL Error.  Could Not Insert QC Test record.'
    rollback tran
    return 68006
  end

    set rowcount 1 
    select @bin = bin_no, @lot = lot_ser, @qty = qty, @dtexp = date_expires
    from lot_bin_prod 
    where tran_no = @src_no and tran_ext = @src_ext and line_no = @line_no and
      location = @loc and part_no = @pn and 
      bin_no + '~' + lot_ser > @bin + '~' + @lot
    order by bin_no + '~' +  lot_ser
    select @rc = @@rowcount
    set rowcount 0

if @rc > 0
begin
update next_qc_no
SET    next_qc_no.last_no=next_qc_no.last_no+1
if @@error <> 0
begin
   raiserror 68002 'SQL Error.  Could Not Get Next QC No.'
   rollback tran
   return 68002
end
SELECT @qno=next_qc_no.last_no
FROM   next_qc_no
if @@error<>0
begin
   raiserror 68003 'SQL Error.  Could Not Get Next QC No.'
   rollback tran
   return 68003
end
if @qno=0 OR @qno is null
begin
   raiserror 68004 'SQL Error.  Could Not Get Next QC No.'
   rollback tran
   return 68004
end
end
  end

  update prod_list set qc_no=@qno where prod_no=@src_no and prod_ext=@src_ext and line_no=@line_no
end 

return 0
GO
GRANT EXECUTE ON  [dbo].[fs_enter_qc] TO [public]
GO
