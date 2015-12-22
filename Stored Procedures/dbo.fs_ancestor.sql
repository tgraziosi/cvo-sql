SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[fs_ancestor] @lot varchar(30)  AS

declare @lev int , @top int, @tran int
select @top=0, @tran=9999999
create table #tmpjob (part_no varchar(30), lot varchar(30), tran_no int, tran_code varchar(30))
select @lev=count(*) from lot_bin_tran where lot_ser=@lot and direction=1 and tran_code='P'
select @tran=max(a.tran_no) from lot_bin_tran a
	where a.lot_ser=@lot and a.direction=1 and a.tran_code='P' 
insert #tmpjob select a.part_no, a.lot_ser, a.tran_no, a.tran_code from lot_bin_prod a
	where a.tran_no=@tran
while @lev > 0 
  begin
    select @tran=max(a.tran_no) from lot_bin_tran a
	  where a.lot_ser=@lot and a.direction=1 and a.tran_code='P' and a.tran_no < @tran
    insert #tmpjob select a.part_no, a.lot_ser, a.tran_no, a.tran_code from lot_bin_prod a
	  where a.tran_no=@tran
    select @lev=count(*) from  lot_bin_tran a
	  where a.lot_ser=@lot and a.direction=1 and a.tran_code='P' and a.tran_no < @tran
    select @top=@top+1
    if @top > 10 select @lev=0
  end
select * from #tmpjob
drop table #tmpjob


GO
GRANT EXECUTE ON  [dbo].[fs_ancestor] TO [public]
GO
