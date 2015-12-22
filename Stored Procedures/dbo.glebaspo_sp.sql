SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[glebaspo_sp]
		@v_from_date		int,
		@v_to_date		int,
 		@importDIN		varchar(20),
		@apply_range		int,
		@v_from_org_id          varchar(32),
		@v_to_org_id            varchar(32)
as

begin

--Call procedure which calculates values for eBAS


if  @v_from_org_id = '<First>' 
  SELECT @v_from_org_id =  MIN(org_id ) from IB_Organization_vw 

if  @v_to_org_id = '<Last>' 
  SELECT @v_to_org_id =  MAX(org_id ) from IB_Organization_vw 
          


if @apply_range = 0
exec 	glebphld_sp 		@v_to_date,@v_from_org_id,@v_to_org_id 
else
exec 	glebphda_sp 		@v_from_date, @v_to_date,@v_from_org_id,@v_to_org_id  

--Flag ebas_holding records with current DIN
update glebhold set din = @importDIN  where 	din = ' '


end
GO
GRANT EXECUTE ON  [dbo].[glebaspo_sp] TO [public]
GO
