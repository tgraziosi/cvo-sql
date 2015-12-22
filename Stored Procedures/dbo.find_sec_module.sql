SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[find_sec_module] @search char(20), @sort char(1), @dist int=0  AS

set rowcount 100
declare @sk1 int, @sk2 int, @product_level int

select @product_level = 
  case @dist 
    when 1 then 17000
    when 2 then 18000
    when 3 then 19000
    else 0
  end

if @sort='U'
begin
SELECT dbo.sec_module.kys,
dbo.smmenus_vw.form_desc, 0
FROM dbo.sec_module, dbo.smmenus_vw
WHERE 
dbo.sec_module.form_id = dbo.smmenus_vw.form_id and 
dbo.smmenus_vw.app_id = 18000 and
dbo.sec_module.kys >= @search and
 ( dbo.smmenus_vw.form_id <= @product_level )
ORDER BY dbo.sec_module.kys ASC 
end
if @sort='N'
begin
SELECT dbo.sec_module.kys,
dbo.smmenus_vw.form_desc, 0
FROM dbo.sec_module, dbo.smmenus_vw
WHERE dbo.sec_module.form_id = dbo.smmenus_vw.form_id and 
 dbo.smmenus_vw.app_id = 18000 and
 dbo.smmenus_vw.form_desc >= @search and
 ( dbo.smmenus_vw.form_id <= @product_level )
ORDER BY dbo.smmenus_vw.form_desc ASC 
end
GO
GRANT EXECUTE ON  [dbo].[find_sec_module] TO [public]
GO
