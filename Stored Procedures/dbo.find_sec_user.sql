SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[find_sec_user] @search char(20), @sort char(1)  AS

set rowcount 100
if @sort='U'
begin
SELECT dbo.sec_user.kys,   
dbo.sec_user.name
FROM dbo.sec_user  
WHERE dbo.sec_user.kys >= @search
ORDER BY dbo.sec_user.kys ASC   
end
if @sort='N'
begin
SELECT dbo.sec_user.kys,   
dbo.sec_user.name
FROM dbo.sec_user  
WHERE dbo.sec_user.name >= @search
ORDER BY dbo.sec_user.name ASC   
end

GO
GRANT EXECUTE ON  [dbo].[find_sec_user] TO [public]
GO
