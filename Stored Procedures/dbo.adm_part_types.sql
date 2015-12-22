SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



create procedure [dbo].[adm_part_types] @mode char(1) = 'D', @descr varchar(30) = ''
AS
BEGIN
create table #types (descr varchar(30), status char(1))

insert #types values( 'Auto-Kit','K')
insert #types values( 'Custom-Kit','C')
insert #types values( 'Make','M')
insert #types values( 'Make/Routed','H')
insert #types values( 'Purchase','P')
insert #types values( 'Purchase/Outsource','Q')

if @mode = 'D'
begin
  select * from #types
  order by status
end
  
END


GO
GRANT EXECUTE ON  [dbo].[adm_part_types] TO [public]
GO
