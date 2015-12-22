SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[get_i_inv_loc] @strsort varchar(50), @sort char(1), @loc varchar(10), @void char(1), @stat char(1), @type varchar(10), @lastkey varchar(30), @username varchar(10)=""  AS

set rowcount 40
declare @minstat char(3)
declare @maxstat char(3)
declare @inv_con varchar(255)
SELECT @minstat = 'A' 
SELECT @maxstat = 'R'
if @stat = 'A' begin
  SELECT @maxstat = 'Q'
end
if @stat = 'M' begin
  SELECT @maxstat = 'M'
end
if @stat = 'P' begin
  SELECT @minstat = 'N'
  SELECT @maxstat = 'Q'
end
if @stat = 'R' begin
  SELECT @minstat = 'R'
  SELECT @maxstat = 'R'
end
if @stat = 'V' begin
  SELECT @minstat = 'V'
  SELECT @maxstat = 'V'
end


select @inv_con=' and ' + isnull((select constrain_by from sec_constraints where kys=@username and table_id='inventory'),'net_inv.part_no=net_inv.part_no')

if @strsort is null select @strsort='null'
select @void='N'
select @maxstat='Q'

 
if @sort='N' begin






if @type = ' ' begin
  SELECT @type = "%"
end

if (@strsort = '' OR @strsort is null) begin
  SELECT @strsort = 'null'
end

if (@strsort = null and @lastkey > "!") OR ( @lastkey >= @strsort ) begin
  SELECT @strsort = @lastkey
end



exec ("select part_no, description, category, sku_no, in_stock, 
       type_code, status, commit_ed, po_on_order
       from net_inv 
       where (part_no >='"+@strsort+
	"' OR '"+@strsort+
	"' = 'null') and location ='"+@loc+
	"' and ('"+@void+"'='null' OR void like '"+@void+
	"') and (type_code like '"+@type+
	"') and  status >='"+@minstat+"' AND status <= '"+@maxstat+"'"+@inv_con+
       " order by part_no ")
end       
  
    
if @sort='D' begin
exec ("select part_no, description, category, sku_no, in_stock, 
       type_code, status, commit_ed, po_on_order
       from net_inv 
       where  ( (description > '"+@strsort+"' OR '"+@strsort+"'='null') OR (description = '"+@strsort+
	"' and part_no >= '"+@lastkey+
	"') ) and location ='"+@loc+
	"' and ('"+@void+"'='null' OR void like '"+@void+
	"') and (type_code like '"+@type+
	"') and  status >='"+@minstat+"' AND status <= '"+@maxstat+"'"+@inv_con+
       " order by description,part_no ")
end     

    
if @sort='K' begin
select @strsort = '%' + @strsort + '%'
exec ("select part_no, description, category, sku_no, in_stock, 
       type_code, status, commit_ed, po_on_order
       from net_inv 
       where  ((description like '"+@strsort+
	"' OR '"+@strsort+
	"'='null') and part_no >= '"+@lastkey+
	"') and location ='"+@loc+
	"' and ('"+@void+"'='null' OR void like '"+@void+
	"') and ('"+@type+"' = '%' OR type_code like '"+@type+
	"') and  status >='"+@minstat+"' AND status <= '"+@maxstat+"'"+@inv_con+
       " order by part_no ")
end     

    
if @sort='S' begin
exec ("select part_no, description, category, sku_no, in_stock, 
       type_code, status, commit_ed, po_on_order
       from net_inv 
       where ( (sku_no > '"+@strsort+
	"' OR '"+@strsort+
	"'='null') OR (sku_no = '"+@strsort+
	"' and part_no >= '"+@lastkey+
	"')) and location ='"+@loc+
	"' and ('"+@void+"'='null' OR void like '"+@void+
	"') and ('"+@type+"' = '%' OR type_code like '"+@type+
	"') and  status >='"+@minstat+"' AND status <= '"+@maxstat+"'"+@inv_con+
        " order by sku_no,part_no")
end         

if @sort='U' begin
exec ("select part_no, description, category, sku_no, in_stock, 
       type_code, status, commit_ed, po_on_order
       from net_inv 
       where ( (upc_code > '"+@strsort+
	"' OR '"+@strsort+
	"' = 'null') OR (upc_code = '"+@strsort+
	"' and part_no >= '"+@lastkey+
	"')) and location ='"+@loc+
	"' and ('"+@void+"'='null' OR void like '"+@void+
	"') and ('"+@type+"' = '%' OR type_code like '"+@type+
	"') and  status >='"+@minstat+"' AND status <= '"+@maxstat+"'"+@inv_con+
        " order by upc_code,part_no")

end        
 

if @sort='C' begin

exec ("select part_no, description, category, sku_no, in_stock, 
       type_code, status, commit_ed, po_on_order
       from net_inv 
       where ( (category > '"+@strsort+
	"' OR '"+@strsort+
	"' = 'null') OR (category = '"+@strsort+
	"' and part_no >= '"+@lastkey+
	"')) and location ='"+@loc+
	"' and ('"+@void+"'='null' OR void like '"+@void+
	"') and ('"+@type+"' = '%' OR type_code like '"+@type+
	"') and  status >='"+@minstat+"' AND status <= '"+@maxstat+"'"+@inv_con+
        " order by category,part_no")
end     


GO
GRANT EXECUTE ON  [dbo].[get_i_inv_loc] TO [public]
GO
