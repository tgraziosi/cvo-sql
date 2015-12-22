SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_qc]  @info varchar(30), @sort char(1), @stat char(1),
                 @loc varchar(10), @qcno int  AS

set rowcount 100
declare @minstat char(1), @maxstat char(1)
declare @x int
select @minstat = 'A', @maxstat = 'Z'
if @stat = 'N'
begin
   select @maxstat = 'N'
end
if @stat = 'S'
begin
   select @minstat = 'S'
   select @maxstat = 'S'
end
if @stat = 'T'
begin
   select @minstat = 'T'
end

if @sort='A'
begin
select @x=convert(int,@info)
select qc_no, part_no, location, lot_ser, tran_code, tran_no, qc_qty,
       status, date_entered, date_complete
from qc_results ( NOLOCK )
where qc_results.tran_code='I' and qc_results.tran_no >= @x and
      qc_results.status>=@minstat and qc_results.status<=@maxstat and
      qc_results.location like @loc
order by tran_no
end

if @sort='C'
begin
select @x=convert(int,@info)
select qc_no, part_no, location, lot_ser, tran_code, tran_no, qc_qty,
       status, date_entered, date_complete
from qc_results ( NOLOCK )
where qc_results.tran_code='C' and qc_results.tran_no >= @x and
      qc_results.status>=@minstat and qc_results.status<=@maxstat and
      qc_results.location like @loc
order by tran_no
end

if @sort='D'
begin
select qc_no, part_no, location, lot_ser, tran_code, tran_no, qc_qty,
       status, date_entered, date_complete
from qc_results ( NOLOCK )
where qc_results.date_entered >= @info AND qc_results.qc_no >= @qcno and
      qc_results.status>=@minstat and qc_results.status<=@maxstat and
      qc_results.location like @loc
order by date_entered, part_no
end

if @sort='I'
begin
select qc_no, part_no, location, lot_ser, tran_code, tran_no, qc_qty,
       status, date_entered, date_complete
from qc_results ( NOLOCK )
where qc_results.part_no >= @info AND qc_results.qc_no >= @qcno and
      qc_results.status>=@minstat and qc_results.status<=@maxstat and
      qc_results.location like @loc
order by part_no
end

if @sort='N'
begin
select @x=convert(int,@info)
select qc_no, part_no, location, lot_ser, tran_code, tran_no, qc_qty,
       status, date_entered, date_complete
from qc_results ( NOLOCK )
where qc_results.qc_no >= @x and
      qc_results.status>=@minstat and qc_results.status<=@maxstat and
      qc_results.location like @loc
order by qc_no
end

if @sort='M'
begin
select @x=convert(int,@info)
select qc_no, part_no, location, lot_ser, tran_code, tran_no, qc_qty,
       status, date_entered, date_complete
from qc_results ( NOLOCK )
where qc_results.tran_code='P' and qc_results.tran_no >= @x and
      qc_results.status>=@minstat and qc_results.status<=@maxstat and
      qc_results.location like @loc
order by tran_no
end

if @sort='P'
begin
select @x=convert(int,@info)
select q.qc_no, q.part_no, q.location, q.lot_ser, 'P', r.po_key, q.qc_qty,
       q.status, q.date_entered, q.date_complete
from qc_results q ( NOLOCK ), receipts r ( NOLOCK )
where q.tran_code='R' and q.tran_no=r.receipt_no and
      r.po_key >= @x and q.qc_no >= @qcno and
      q.status>=@minstat and q.status<=@maxstat and
      q.location like @loc
order by r.po_key, q.tran_no								-- mls 2/1/01 SCR 24604
end

if @sort='R'
begin
select @x=convert(int,@info)
select qc_no, part_no, location, lot_ser, tran_code, tran_no, qc_qty,
       status, date_entered, date_complete
from qc_results ( NOLOCK )
where qc_results.tran_code='R' and qc_results.tran_no >= @x and
      qc_results.status>=@minstat and qc_results.status<=@maxstat and
      qc_results.location like @loc
order by tran_no
end

GO
GRANT EXECUTE ON  [dbo].[get_q_qc] TO [public]
GO
