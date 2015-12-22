SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[adm_get_rank_sp] 
			@a_perc  float,	
			@c_perc  float,
			@rank_by  int,	
			@from_loc  varchar(30),
			@thru_loc  varchar(30),
			@from_part  varchar(30),
			@thru_part  varchar(30),
			@from_class  varchar(30),
			@thru_class  varchar(30),
			@from_date  varchar(30),
			@thru_date   varchar(30),
			@rep int
			as

declare @sql varchar(4000)		
		
create table #inventory_temp(
location	varchar(10),
part_no		varchar(30),
description	varchar(255),
category		varchar(10),
sales_amt		float,
rank_class	varchar(10),
ilevel int,
prow_id int,
row_id int identity(1,1)
)	 
			

DECLARE @item_flag  	integer,
	@total_value  	float,
	@par_no  	varchar(30),
	@where_items  	varchar(255),
	@where_locations  varchar(255),
	@where_classes  varchar(255),
	@rank  		char(1),
	@max_value  	float,
	@var1  		varchar(32),
	@value_col  	varchar(1200),
	@group_by 	varchar(75),
	@cnt int, @rowcnt int

 SELECT @group_by = ' a.category,a.description,b.location,a.part_no'
 

if @rank_by = 1 	
	select @value_col = ' SUM(c.shipped * c.price) '

else if @rank_by = 2 	
	select @value_col = ' SUM(c.shipped ) '

else if @rank_by = 3 	
	select @value_col = ' SUM((c.shipped ) * (c.price - c.cost)) '


else if @rank_by = 4 	
	select @value_col = ' SUM((c.shipped )* (c.cost/c.price)) '


else if @rank_by = 5 	
	select @value_col = ' AVG(c.shipped * c.cost) '


else if @rank_by = 6 
BEGIN
	SELECT @value_col = ' CASE WHEN b.inv_cost_method = ''A'' THEN (b.in_stock * b.avg_cost) ' +
' WHEN b.inv_cost_method = ''S'' THEN (b.in_stock * b.std_cost) ' +
' WHEN b.inv_cost_method = ''F'' THEN (b.in_stock * b.avg_cost) ' +
' WHEN b.inv_cost_method = ''L'' THEN (b.in_stock * b.avg_cost) ' +
' ELSE (b.in_stock * b.std_util_dolrs) END '
	SELECT @group_by  = ''
END



if @from_loc <> '' 
	select @where_locations = ' b.location >= ''' + @from_loc + ''' AND '
else
	select @where_locations = ' 1=1 AND '

if @thru_loc <> '' 
	select @where_locations = @where_locations + ' b.location <= ''' + @thru_loc + '''' 
else
	select @where_locations = ' 1=1 '



if @from_part <> '' 
	select @where_items = ' b.part_no >= ''' + @from_part + ''' AND '
else
	select @where_items = ' 1=1 AND '

if @thru_part <> '' 
	select @where_items = @where_items + ' b.part_no <= ''' + @thru_part + '''' 
else
	select @where_items = ' 1=1 '	


if @from_class <> '' 
	select @where_classes = ' b.category >= ''' + @from_class + ''' AND '
else
	select @where_classes = ' 1=1 AND '

if @thru_class <> '' 
	select @where_classes = @where_classes + ' b.category <= ''' + @thru_class + ''''
else
	select @where_classes =  ' 1=1 '

if @rank_by = 6
begin
select @sql = 'INSERT INTO #inventory_temp (' +
'location, part_no, description,category,sales_amt,rank_class,ilevel, prow_id) ' +
	'SELECT 	' +
	'	b.location ' +
	'	,b.part_no ' +
	'	,b.description' +
	'	,b.category ,' + 	@value_col + 
	'	,'''',1,0 ' + 
	'	FROM inventory b, locations l' +
	'	WHERE' + 
	'	l.location = b.location ' +
	'	and isnull(b.void,''N'') != ''V''' +
	'	AND ' + @where_items + 
	'	AND ' + @where_locations +
	'	AND ' + @where_classes 

end
else
begin
select @sql = 'INSERT INTO #inventory_temp (' +
'location, part_no, description,category,sales_amt,rank_class,ilevel, prow_id) ' +
	'SELECT 	' +
	'	b.location ' +
	'	,a.part_no ' +
	'	,a.description' +
	'	,a.category ,' + 	@value_col + 
	'	,'''',1,0 ' + 
	'	FROM inv_master a, inv_list b, locations l, ord_list c' +
	'	WHERE' + 
	'	a.part_no = b.part_no and l.location = b.location ' +
	'	and isnull(a.void,''N'') != ''V''' +
	'	AND b.part_no = c.part_no ' +
	'	AND b.location = c.location ' +
	'	AND c.time_entered >= convert(datetime,''' + @from_date + ''') AND c.time_entered <= (convert(datetime,''' + @thru_date + ''' ) + 1 )' +
	'	AND ' + @where_items + 
	'	AND ' + @where_locations +
	'	AND ' + @where_classes +
	'	GROUP BY ' + @group_by 
end
EXEC (@sql)


select @cnt = count(*) from #inventory_temp












-- A
set @rowcnt = @cnt *(@a_perc /100)

set rowcount @rowcnt
INSERT INTO #inventory_temp (location, part_no, description,category,sales_amt,rank_class,ilevel,prow_id)
select location, part_no, description,category,sales_amt,'A',2,row_id
from #inventory_temp
order by sales_amt desc, part_no

set rowcount 0
update t1
set rank_class = 'A'
from #inventory_temp t1, #inventory_temp t2
where t1.row_id = t2.prow_id
and t2.ilevel = 2 

set @rowcnt = @cnt *(@c_perc /100)
set rowcount @rowcnt
INSERT INTO #inventory_temp (location, part_no, description,category,sales_amt,rank_class,ilevel,prow_id)
select location, part_no, description,category,sales_amt,'C',2,row_id
from #inventory_temp
where ilevel = 1 and rank_class = ''
order by sales_amt , part_no

set rowcount 0
update t1
set rank_class = 'C'
from #inventory_temp t1, #inventory_temp t2
where t1.row_id = t2.prow_id
and t2.ilevel = 2  and t2.rank_class = 'C'

INSERT INTO #inventory_temp (location, part_no, description,category,sales_amt,rank_class,ilevel,prow_id)
select location, part_no, description,category,sales_amt,'B',2,row_id
from #inventory_temp
where ilevel = 1 and rank_class = ''


IF @rep != 1
	UPDATE inv_list
	SET rank_class = b.rank_class
	FROM inv_list a, #inventory_temp b
	WHERE 	a.part_no = b.part_no
	AND 	a.location = b.location
	AND	b.ilevel = 2
	


select a.*, space(40) b_loc, 
	    space(40) b_item, 
	    space(40) b_class, 
	    space(40) b_date, 
	    space(40) e_loc, 
	    space(40) e_item, 
	    space(40) e_class, 
	    space(40) e_date,
	    space(40) rank_by,
	    space(40) aperc,
	    space(40) bperc,
	    space(40) cperc  
FROM #inventory_temp a
where a.ilevel = 2
GO
GRANT EXECUTE ON  [dbo].[adm_get_rank_sp] TO [public]
GO
