SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cvo_inv_aging_pom_sp] 
(@asofdate datetime, @loc varchar(12), @type varchar(1000) )
as

set nocount on

-- declare @asofdate datetime, @loc varchar(12), @type varchar(1000)

IF(OBJECT_ID('tempdb.dbo.#type') is not null)  drop table #type 
CREATE TABLE #type ([restype] VARCHAR(10))
INSERT INTO #type ([restype])
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@type)

/*
select @asofdate = getdate()
select @loc = '001'
select @type = 'frame'
*/

select cia.brand, cia.restype, cia.style, cia.part_no, cia.description, 
	   cia.pom_date, 
	   age = case  when cia.pom_date > @asofdate then 'Future'
				   when cia.pom_date >= dateadd(yy,-1,@asofdate) then '<1'
				   when cia.pom_date >= dateadd(yy,-2,@asofdate) and cia.pom_date < dateadd(yy,-1,@asofdate) then '<2'
				   when cia.pom_date >= dateadd(yy,-3,@asofdate) and cia.pom_date < dateadd(yy,-2,@asofdate) then '<3'
				   when cia.pom_date < dateadd(yy,-3,@asofdate) then '>3'
				   else 'Unknown'
				   end,
	   cia.tot_cost_ea, cia.tot_ext_cost, cia.in_stock, cia.qty_avl , cia.sof, cia.allocated, cia.quarantine,
	   cia.non_alloc, cia.replen_qty_not_sa, cia.replenqty
from cvo_item_avail_vw cia (nolock) 
inner join #type on #type.restype = cia.restype
where cia.pom_date is not null and cia.pom_date <=@asofdate
and location = @loc
and (cia.in_stock <> 0 or cia.tot_ext_cost <> 0)

GO
GRANT EXECUTE ON  [dbo].[cvo_inv_aging_pom_sp] TO [public]
GO
