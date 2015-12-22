SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[fs_cParsing] (@SEARCH VARCHAR(MAX))       
      
RETURNS @retisoc_tab table (valor varchar(MAX)) AS       
      
BEGIN       
      
declare @pos int,@isoc varchar(MAX),@strlen int      
      
declare @isoc_tab table (valor varchar(MAX))      
      
set @search = ltrim(rtrim(@search))      
      
      
while len(@search) >=0      
      
begin      
      
set @strlen = len(ltrim(@search))      
      
set @pos = charindex(',',@search,1)      
      
if @pos=0 and @search is not null      
      
begin      
      
set @search = ltrim(rtrim(@search))      
      
insert into @isoc_tab values(@search)      
      
insert into @retisoc_tab select * from @isoc_tab      
      
return      
      
end      
      
set @isoc = substring(rtrim(ltrim(@search)),1,@pos-1)      
      
insert into @isoc_tab values(@isoc)      
      
set @search = ltrim(right(@search,@strlen-@pos))      
      
end      
      
return      
END 
GO
GRANT REFERENCES ON  [dbo].[fs_cParsing] TO [public]
GO
