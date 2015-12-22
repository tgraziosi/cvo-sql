SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- exec cvo_std_cost_sync_sp


CREATE PROCEDURE [dbo].[cvo_STD_Cost_Sync_sp]  AS
BEGIN
SET NOCOUNT ON

/* Sync Costs in <>001 locations with the cost in 001 */
/* TAG - 2/2012 
	10/26/2012 - added support for items not in location 001
*/

Create Table #CostDiff
(part_no	varchar(32),
 location	varchar(10),
 std_cost_001	decimal(20,8),
 std_ovhd_001	decimal(20,8),
 std_util_001	decimal(20,8),
 id int IDENTITY (1,1)
)

Create Index cd1_idx on #CostDiff (part_no, location)

Insert into #costdiff
select distinct inv1.part_no, 
inv1.location,
isnull(inv1.std_cost,0) as std_cost_001, 
isnull(inv1.std_ovhd_dolrs,0) as std_ovhd_001,
isnull(inv1.std_util_dolrs,0) as std_util_001
from inv_list inv1 (nolock)
inner join inv_master i (nolock) on inv1.part_no = i.part_no
left outer join inv_list inv2 (nolock) on inv1.part_no = inv2.part_no
where (inv1.location = '001') and (inv2.location NOT IN ( '001','BlueTech'))
and ((inv1.std_cost <> inv2.std_cost or inv1.std_cost is null or inv2.std_cost is null) or
	(inv1.std_ovhd_dolrs <> inv2.std_ovhd_dolrs or inv1.std_ovhd_dolrs is null or 
     inv2.std_ovhd_dolrs is null) or 
	(inv1.std_util_dolrs <> inv2.std_util_dolrs or inv2.std_util_dolrs is null or 
     inv2.std_util_dolrs is null))
and exists (select 1 from in_account ii where ii.acct_code = inv2.acct_code)
union all
select distinct inv1.part_no, 
inv1.location,
isnull(inv1.std_cost,0) as std_cost_001, 
isnull(inv1.std_ovhd_dolrs,0) as std_ovhd_001,
isnull(inv1.std_util_dolrs,0) as std_util_001
from inv_list inv1 (nolock)
inner join inv_master i (nolock) on inv1.part_no = i.part_no
left outer join inv_list inv2 (nolock) on inv1.part_no = inv2.part_no
where (inv1.location NOT IN ( '001' ,'BlueTech')	
AND (inv1.std_cost <> 0 or inv1.std_ovhd_dolrs <> 0 or inv1.std_util_dolrs <> 0) )
	and not exists (select location from inv_list inv where i.part_no = inv.part_no
					and inv.location = '001')
	and (inv2.location <> inv1.location )
and ((inv1.std_cost <> inv2.std_cost or inv1.std_cost is null or inv2.std_cost is null) or
	(inv1.std_ovhd_dolrs <> inv2.std_ovhd_dolrs or inv1.std_ovhd_dolrs is null or 
     inv2.std_ovhd_dolrs is null) or 
	(inv1.std_util_dolrs <> inv2.std_util_dolrs or inv2.std_util_dolrs is null or 
     inv2.std_util_dolrs is null))
and exists (select 1 from in_account ii where ii.acct_code = inv1.acct_code)

declare @costdiff int
select @costdiff = count(*) from #costdiff

if @costdiff > 0
Begin
	
	declare @part varchar(32),
		@location varchar(10),
		@STD_COST_001 decimal(20,8),
		@std_ovhd_001 decimal(20,8),
		@std_util_001 decimal(20,8),
		@id INT;

	SELECT @id = 0

	SELECT @id = MIN(id) FROM #costdiff WHERE id > @id
	SELECT @part = part_no, @location = location
		, @std_cost_001 = std_cost_001
		, @std_ovhd_001 = std_ovhd_001
		, @std_util_001 = std_util_001
	FROM #CostDiff WHERE id > @id
	
	while @id IS NOT NULL
	begin

		BEGIN TRANSACTION 
		update inv_list 
		set std_cost=@std_cost_001, std_ovhd_dolrs=@std_ovhd_001, std_util_dolrs=@std_util_001
			from inv_list i (nolock) 
			where i.part_no = @part and i.location NOT IN ( @location, 'BlueTech')
		COMMIT TRANSACTION
	
		SELECT @id = MIN(id) FROM #costdiff WHERE id > @id
		SELECT @part = part_no, @location = location
		, @std_cost_001 = std_cost_001
		, @std_ovhd_001 = std_ovhd_001
		, @std_util_001 = std_util_001
		FROM #CostDiff WHERE id = @id
	end
	
End

select * from #costdiff

Drop table #costdiff

END
GO
GRANT EXECUTE ON  [dbo].[cvo_STD_Cost_Sync_sp] TO [public]
GO
