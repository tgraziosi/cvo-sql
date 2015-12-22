SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_part] @strsort varchar(30), @sort char(1), @void char(1)  AS

set rowcount 100
 
if @sort='N' begin
select part_no, description, category, sku_no, upc_code, in_stock, min_order 
from inventory
where   (inventory.part_no >= @strsort OR @strsort is null) and 
(void is NULL OR void like @void)         
order by inventory.part_no
end         
    
if @sort='D' begin
select part_no, description, category, sku_no, upc_code, in_stock, min_order 
from inventory
where   (inventory.description >= @strsort OR @strsort is null) and 
(void is NULL OR void like @void)     
order by inventory.description
end     
    
if @sort='S' begin
select part_no, description, category, sku_no, upc_code, in_stock, min_order 
from inventory
where   (inventory.sku_no >= @strsort OR @strsort is null) and 
(void is NULL OR void like @void)  
order by inventory.sku_no
end         

if @sort='U' begin
select part_no, description, category, sku_no, upc_code, in_stock, min_order 
from inventory
where   (inventory.upc_code >= @strsort OR @strsort is null) and 
(void is NULL OR void like @void)  
order by inventory.upc_code
end         

if @sort='C' begin
select part_no, description, category, sku_no, upc_code, in_stock, min_order 
from inventory
where   (inventory.category >= @strsort OR @strsort is null) and 
(void is NULL OR void like @void)  
order by inventory.category, inventory.description
end     

GO
GRANT EXECUTE ON  [dbo].[get_q_part] TO [public]
GO
